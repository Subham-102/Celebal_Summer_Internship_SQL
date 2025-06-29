create table StudentDetails(
StudentId int primary key,
StudentName varchar(255),
GPA float,
Branch varchar(255),
Section char(1)
);

create table SubjectDetails(
SubjectId varchar(255) primary key,
SubjectName varchar(255),
MaxSeats int,
RemainingSeats int
);

create table StudentPreference(
StudentId int,
SubjectId varchar (255),
Preference int,
foreign key (StudentId) references StudentDetails(StudentId),
foreign key (SubjectId) references SubjectDetails(SubjectId),
primary key(StudentId,SubjectId)
);

create table Allotments(
SubjectId varchar (255),
StudentId int,
foreign key (StudentId) references StudentDetails(StudentId),
foreign key (SubjectId) references SubjectDetails(SubjectId),
primary key(StudentId,SubjectId)
);

create table UnallotedStudents(
StudentId int primary key,
foreign key (StudentId) references StudentDetails(StudentId)
);

create procedure AllocateSubjects
as
begin
declare @StudentId int
declare @Preference int
declare @SubjectId varchar(255)
declare @RemainingSeats int
declare StudentCursor cursor for
select StudentId from StudentDetails
order by GPA desc

open StudentCursor
fetch next from StudentCursor into @StudentId
while @@FETCH_STATUS = 0
begin set @Preference = 1
declare @Allocated bit
set @Allocated = 0
while @Preference <=5 and @Allocated = 0
begin
select @SubjectId=SubjectId
from StudentPreference
where StudentId = @StudentId and Preference=@Preference
if @RemainingSeats > 0
begin
insert into Allotments (SubjectId,StudentId)
values(@SubjectId,@StudentId)
update SubjectDetails
set RemainingSeats = RemainingSeats-1
where SubjectId=@SubjectId
set @Allocated = 1
end
set @Preference=@Preference+1
end
if @Allocated = 0
begin
insert into UnallotedStudents(StudentId)
values(@StudentId)
end
fetch next from StudentCursor into @StudentId
end
close StudentCursor
deallocate StudentCursor
end

insert into studentdetails (studentid, studentname, gpa, branch, section)
values
(159103036, 'Mohit Agarwal', 8.9, 'CCE', 'A'),
(159103037, 'Rohit Agarwal', 5.2, 'CCE', 'A'),
(159103038, 'Shohit Garg', 7.1, 'CCE', 'B'),
(159103039, 'Mrinal Malhotra', 7.9, 'CCE', 'A'),
(159103040, 'Mehreet Singh', 5.6, 'CCE', 'A'),
(159103041, 'Arjun Tehlan', 9.2, 'CCE', 'B');

insert into subjectdetails (subjectid, subjectname, maxseats, remainingseats)
values
('PO1491', 'Basics of Political Science', 60, 2),
('PO1492', 'Basics of Accounting', 120, 119),
('PO1493', 'Basics of Financial Markets', 90, 90),
('PO1494', 'Eco philosophy', 60, 50),
('PO1495', 'Automotive Trends', 60, 60);

insert into studentpreference (studentid, subjectid, preference)
values
(159103036, 'PO1491', 1),
(159103036, 'PO1492', 2),
(159103036, 'PO1493', 3),
(159103036, 'PO1494', 4),
(159103036, 'PO1495', 5),
(159103037, 'PO1492', 1),
(159103037, 'PO1493', 2),
(159103037, 'PO1494', 3),
(159103037, 'PO1495', 4);

exec AllocateSubjects;
