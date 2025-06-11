CREATE TABLE  "DEMO_SDLC" 
   (	"SDLCNO" NUMBER(2,0), 
	"SDLCNAME" VARCHAR2(15), 
	 PRIMARY KEY ("SDLCNO")
  USING INDEX  ENABLE
   );

Create table DEMO_TASK
   (	"ID" NUMBER NOT NULL ENABLE, 
	"TASK_NAME" VARCHAR2(255), 
	"TASK_DESCRIPTION" VARCHAR2(4000), 
	"START_DATE" DATE, 
	"END_DATE" DATE, 
	"STATUS" VARCHAR2(30), 
	"USERID" NUMBER,
        "PROJECT_ID" VARCHAR2(10),
        "SDLCNO" NUMBER(2,0),
        "PROJECT_ICON" VARCHAR2(25)
   );   


insert into demo_sdlc values (10,'PLANNING');
insert into demo_sdlc values (20,'ANALYSIS');
insert into demo_sdlc values (30,'DESIGN');
insert into demo_sdlc values (40,'IMPLEMENTATION');
insert into demo_sdlc values (50,'MAINTENANCE');


insert into demo_task values (1,'Create applications from spreadsheets', 'Description of Create applications from spreadsheets', to_date('03-11-2019','mm-dd-yyyy'), to_date('03-15-2019','mm-dd-yyyy'), 'Open', 1, 'PRJ-123', 10, 'fa fa-calendar-edit');

insert into demo_task values (2,'Send links to previous spreadsheet owners', 'Description of Send links to previous spreadsheet owners', to_date('03-03-2019','mm-dd-yyyy'), to_date('03-09-2019','mm-dd-yyyy'), 'Pending', 2, 'PRJ-123', 20, 'fa fa-clipboard-list');

insert into demo_task values (3,'Specify security authentication scheme(s)', 'Description of Specify security authentication scheme(s)', to_date('03-18-2019','mm-dd-yyyy'), to_date('03-20-2019','mm-dd-yyyy'), 'On-Hold', 3, 'PRJ-123', 30, 'fa fa-database');

insert into demo_task values (4,'Configure Workspace provisioning', 'Description of Configure Workspace provisioning', to_date('03-25-2019','mm-dd-yyyy'), to_date('03-25-2019','mm-dd-yyyy'), 'Closed', 4, 'PRJ-123', 40, 'fa fa-flag-checkered');

insert into demo_task values (5,'Service Level Agreeement', 'Description of Service Level Agreement', to_date('01-01-2019','mm-dd-yyyy'), to_date('12-31-2020','mm-dd-yyyy'), 'Pending', 5, 'PRJ-123', 50, 'fa fa-calendar-wrench');
