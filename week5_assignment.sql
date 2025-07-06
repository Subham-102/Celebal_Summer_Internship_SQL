create procedure UpdateSubjectAllotments
    @StudentID varchar(50),
    @RequestedSubjectID varchar(50)
as
begin
    set nocount on;

    declare @CurrentSubjectID varchar(50);
    select @CurrentSubjectID = SubjectID
    from SubjectAllotments
    where StudentID = @StudentID
      and Is_Valid = 1;

    if @CurrentSubjectID is null
    begin
      
        insert into SubjectAllotments (StudentID, SubjectID, Is_Valid)
        values (@StudentID, @RequestedSubjectID, 1);
    end
    else
    begin
       
        if @CurrentSubjectID <> @RequestedSubjectID
        begin
           
            update SubjectAllotments
            set Is_Valid = 0
            where StudentID = @StudentID
              and Is_Valid = 1;

         
            insert into SubjectAllotments (StudentID, SubjectID, Is_Valid)
            values (@StudentID, @RequestedSubjectID, 1);
        end
        
    end
end;
