-- 1. Table to store JSON Enrollment Data
CREATE TABLE Enrollment_Details (
    EnrollmentID INT IDENTITY(1,1) PRIMARY KEY,
    EnrollmentDate DATETIME DEFAULT GETDATE(),
    ResourceGroupName varchar(125) NOT NULL,
	DBWatchername varchar(125) NOT NULL,
	DBWatcherlocation varchar(50) NOT NULL,
	EnrollmentJSON JSON NOT NULL 
);


-- 2. Table to store Azure SQL Target Details 
/****** Object:  Table [dbo].[Targets]    Script Date: 7/24/2026 10:55:06 AM ******/
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
	[EnrolledDate] [datetime2](7) NULL,
PRIMARY KEY CLUSTERED 
(
	[ServerID] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Targets] ADD  DEFAULT (getdate()) FOR [RegistrationDate]
GO

ALTER TABLE [dbo].[Targets] ADD  DEFAULT (getdate()) FOR [EnrolledDate]
GO


