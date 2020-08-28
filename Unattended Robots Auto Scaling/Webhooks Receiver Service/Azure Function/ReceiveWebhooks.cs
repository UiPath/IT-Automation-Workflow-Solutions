using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json.Linq;
using RestSharp;
using System.Linq;

namespace UiPath.WorkflowSolutions.RobotAutoScaling.Function
{    
    public static class ReceiveWebhooks
    {                
        [FunctionName("ReceiveWebhooks")]
        public static async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = null)] HttpRequest req, ILogger log)
        {
            // get event data
            var message = await new StreamReader(req.Body).ReadToEndAsync();
            // get required properties from event data
            var eventData = JObject.Parse(message);
            var dataType = eventData["Type"].ToString();            
            var tenantId = eventData["TenantId"].ToString();
            var folderId = eventData["OrganizationUnitId"].ToString();
            var eventId = eventData["EventId"].ToString();
            var timestamp = eventData["Timestamp"].ToString();                    
            var jobCount = "1";
            var releaseId = "";
            var releaseProcessKey = "";            
            if (dataType == "job.created")
            {
                jobCount = eventData["Jobs"].Count().ToString();
                releaseId = eventData["Jobs"].FirstOrDefault()["Release"]["Id"].ToString();
                releaseProcessKey = eventData["Jobs"].FirstOrDefault()["Release"]["ProcessKey"].ToString();
                log.LogInformation($"{dataType} ({eventData["Jobs"].Count()}) in tenant {eventData["TenantId"]} at {eventData["Timestamp"]}");
            }
            else
            {
                var jobEvent = new string[] {"job.completed", "job.faulted", "job.stopped"};
                if(jobEvent.Contains(dataType))
                {
                    releaseId = eventData["Job"]["Release"]["Id"].ToString();
                    releaseProcessKey = eventData["Job"]["Release"]["ProcessKey"].ToString();
                }
                log.LogInformation($"{dataType} in tenant {eventData["TenantId"]} at {eventData["Timestamp"]}");
            }

            // filter out the events triggered by the admin jobs (when managing client folders from the same Orchestrator tenant)
            if((tenantId != Constants.AdminTenantId) || ((tenantId == Constants.AdminTenantId) && (folderId != Constants.AdminOrganizationUnitId)))            
            {                
                var itemEventData = "{ \"itemData\": { \"Name\": \""+ Constants.AdminEventsQueueName + "\", \"Reference\": \"" + dataType + "_"+ tenantId + "_" + eventId + "\", \"SpecificContent\": { \"Action\": \"webhook\", \"DataType\": \"" + dataType + "\", \"JobCount\": \"" + jobCount + "\", \"TenantId\": \"" + tenantId + "\", \"Timestamp\": \"" + timestamp + "\", \"EventId\": \""+ eventId + "\", \"OrganizationUnitId\": \"" + folderId + "\", \"ReleaseId\": \"" + releaseId + "\", \"ReleaseProcessKey\": \"" + releaseProcessKey + "\" } } }";             
                var response = await OrchestratorHelper.AddNewQueueItem(itemEventData);
                log.LogInformation($"Requested AddNewQueueItem: ResponseStatus({response.ResponseStatus}), ResponseStatusCode({response.StatusCode})");
            }

            return new OkObjectResult("OK");
        }
    }


    // admin tenant info
    public static class Constants
    {
        // TRUE - on-prem constants will be used for the Orchestrator requests to add webhook event as new Queue Item
        // FALSE - cloud api constants will be used for the Orchestrator requests to add webhook event as new Queue Item
        internal static readonly bool AdminOrchestratorIsOnprem = false;

        #region common
        internal static readonly string AdminOrganizationUnitId = "";
        internal static readonly string AdminTenantId = "";
        internal static readonly string AdminEventsQueueName = "";
        #endregion

        #region on-prem
        internal static readonly string AdminOnpremTenantName = "";
        internal static readonly string AdminOnpremTenantUsername = "";
        internal static readonly string AdminOnpremTenantPassword = "";
        internal static readonly string AdminOnpremTenantAuthUrl = "https://YOUR-ORCHESTRATOR-AUTH-URL/api/Account/Authenticate";
        internal static readonly string AdminOnpremTenantUrl = "https://YOUR-ORCHESTRATOR-AUTH-URL";
        #endregion
        
        #region cloud api
        internal static readonly string AdminAccountLogicalName = "";
        internal static readonly string AdminTenantLogicalName = "";
        internal static readonly string AdminClientId = "";
        internal static readonly string AdminUserKey = "";
        internal static readonly string AdminAuthUrl = "https://account.uipath.com/oauth/token";
        internal static readonly string AdminTenantUrl = $"https://platform.uipath.com/{AdminAccountLogicalName}/{AdminTenantLogicalName}";
        #endregion
    }


    public static class OrchestratorHelper
    {
        public static async Task<string> Authenticate()
        {
            IRestResponse response;            
            var request = new RestRequest(Method.POST);
            request.AddHeader("Content-Type", "application/json");
            if(Constants.AdminOrchestratorIsOnprem){
                request.AddParameter("application/json", "{ \"tenancyName\": \""+Constants.AdminOnpremTenantName+"\", \"usernameOrEmailAddress\": \""+Constants.AdminOnpremTenantUsername+"\", \"password\": \""+Constants.AdminOnpremTenantPassword+"\"}", ParameterType.RequestBody);                
                var client = new RestClient(Constants.AdminOnpremTenantAuthUrl) { Timeout = -1 };
                response = await client.ExecuteAsync(request);
                return JObject.Parse(response.Content)["result"].ToString();                
            }
            else
            {
                request.AddHeader("X-UIPATH-TenantName", Constants.AdminTenantLogicalName);
                request.AddParameter("application/json", "{ \"grant_type\": \"refresh_token\", \"client_id\": \""+Constants.AdminClientId+"\", \"refresh_token\": \""+Constants.AdminUserKey+"\"}", ParameterType.RequestBody);
                var client = new RestClient(Constants.AdminAuthUrl) { Timeout = -1 };
                response = await client.ExecuteAsync(request);
                return JObject.Parse(response.Content)["access_token"].ToString();
            }            
        }

        public static async Task<IRestResponse> AddNewQueueItem(string requestBody)
        {
            string url, tenantName;
            var token = await Authenticate();
            var request = new RestRequest(Method.POST);
            if(Constants.AdminOrchestratorIsOnprem)
            {
                url = Constants.AdminOnpremTenantUrl;
            }
            else
            {
                url = Constants.AdminTenantUrl;
                tenantName = Constants.AdminTenantLogicalName;     
                request.AddHeader("X-UIPATH-TenantName", $"{tenantName}");           
            }
            var client = new RestClient($"{url}/odata/Queues/UiPathODataSvc.AddQueueItem") { Timeout = -1 };
            request.AddHeader("Content-Type", "application/json");
            request.AddHeader("X-UIPATH-OrganizationUnitId", $"{Constants.AdminOrganizationUnitId}");
            request.AddHeader("Authorization", $"Bearer {token}");            
            request.AddParameter("application/json", requestBody, ParameterType.RequestBody);
            var response = await client.ExecuteAsync(request);
            return response;
        }
    }
}
