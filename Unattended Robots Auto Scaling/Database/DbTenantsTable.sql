/****** Object:  Table [dbo].[Tenants]   ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tenants](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[TenantId] [int] NOT NULL,
	[AccountLogicalName] [nvarchar](250) NULL,
	[TenantLogicalName] [nvarchar](250) NOT NULL,
	[ClientId] [nvarchar](250) NOT NULL,
	[UserKey] [nvarchar](250) NOT NULL,
	[AuthUrl] [nvarchar](250) NOT NULL,
	[OrchestratorUrl] [nvarchar](250) NOT NULL,
	[OrchestratorFolder] [nvarchar](250) NOT NULL,
	[OrchestratorFolderId] [int] NULL,
	[OrchestratorEnvironmentName] [nvarchar](250) NULL,
	[RobotsCountHot] [int] NOT NULL,
	[RobotsCountCold] [int] NOT NULL,
	[RobotsCountVirtual] [int] NOT NULL,
	[VmTemplate] [nvarchar](250) NOT NULL,
	[InfrastructureType] [nvarchar](250) NOT NULL,
	[Notes] [nvarchar](250) NULL,
 CONSTRAINT [PK_Tenants] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Tenants] ADD  CONSTRAINT [DF_Tenants_TenantId]  DEFAULT ((0)) FOR [TenantId]
GO
ALTER TABLE [dbo].[Tenants] ADD  CONSTRAINT [DF_Tenants_AuthUrl]  DEFAULT (N'https://account.uipath.com/oauth/token') FOR [AuthUrl]
GO
ALTER TABLE [dbo].[Tenants] ADD  CONSTRAINT [DF_Tenants_OrchestratorUrl]  DEFAULT (N'https://platform.uipath.com/') FOR [OrchestratorUrl]
GO
ALTER TABLE [dbo].[Tenants] ADD  CONSTRAINT [DF_Tenants_OrchestratorFolderName]  DEFAULT (N'Default') FOR [OrchestratorFolder]
GO
ALTER TABLE [dbo].[Tenants] ADD  CONSTRAINT [DF_Tenants_RobotsCountHot]  DEFAULT ((0)) FOR [RobotsCountHot]
GO
ALTER TABLE [dbo].[Tenants] ADD  CONSTRAINT [DF_Tenants_RobotsCountCold]  DEFAULT ((0)) FOR [RobotsCountCold]
GO
ALTER TABLE [dbo].[Tenants] ADD  CONSTRAINT [DF_Tenants_RobotsCountVirtual]  DEFAULT ((0)) FOR [RobotsCountVirtual]
GO
ALTER TABLE [dbo].[Tenants] ADD  CONSTRAINT [DF_Tenants_InfrastructureType]  DEFAULT (N'azure') FOR [InfrastructureType]
GO
