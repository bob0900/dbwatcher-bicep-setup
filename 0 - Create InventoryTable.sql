/****** Object:  Table [dbo].[Targets]    Script Date: 7/14/2026 4:32:53 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Targets](
	[ServerID] [int] IDENTITY(1,1) NOT NULL,
	[servername] [nvarchar](80) NOT NULL,
	[servertype] [nvarchar](80) NOT NULL,
	[contactperson] [varchar](100) NOT NULL,
	[dbwatchername] [varchar](80) NULL,
	[enrolled] [varchar](1) NULL,
	[RegistrationDate] [datetime2](7) NULL,
	[DBNAME] [varchar](255) NULL,
	[ServiceTier] [varchar](255) NULL,
	[ComputeTier] [varchar](255) NULL,
	[DeploymentModel] [varchar](255) NULL,
	[AdminName] [varchar](75) NULL,
	[ResourceGroupName] [varchar](255) NULL,
	[SubscriptionID] [varchar](255) NULL,
	[SubscriptionName] [varchar](255) NULL,
PRIMARY KEY CLUSTERED 
(
	[ServerID] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Targets] ADD  DEFAULT (getdate()) FOR [RegistrationDate]
GO


CREATE TABLE [dbo].[OnboardingData](
	[OnboardID] [int] IDENTITY(1,1) NOT NULL,
	[dbwatchername] [varchar](80) NULL,
	[RegistrationDate] [datetime2](7) NULL,
	[ResourceGroupName] [varchar](255) NULL,
	[SubscriptionName] [varchar](255) NULL,
	[InputData] [varchar](max) NULL,
PRIMARY KEY CLUSTERED 
(
	[OnboardID] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[OnboardingData] ADD  DEFAULT (getdate()) FOR [RegistrationDate]
GO
