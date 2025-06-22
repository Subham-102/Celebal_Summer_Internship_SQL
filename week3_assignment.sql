-- Task - 1
with TaskGroup as (
    select
        Task_ID,
        Start_Date,
        End_Date,
        ROW_NUMBER() OVER (order by Start_Date) - 
        ROW_NUMBER() OVER (PARTITION by DATEADD(day, -ROW_NUMBER() OVER (order by Start_Date), Start_Date) order by Start_Date) as Project_ID
    from Projects
)
select
    MIN(Start_Date) as Start_Date,
    MAX(End_Date) as End_Date,
    DATEDIFF(day, MIN(Start_Date), MAX(End_Date)) + 1 as Duration
from TaskGroup
group by Project_ID
order by Duration, MIN(Start_Date);

-- Task - 2
select
    s1.Name AS StudentName,
    s2.Name AS BestFriendName,
    p2.Salary AS BestFriendSalary
from
    Students s1
join
    Friends f on s1.ID = f.ID
join
    Students s2 on f.Friend_ID = s2.ID
join
    Packages p1 on s1.ID = p1.ID
join
    Packages p2 on s2.ID = p2.ID
where
    p2.Salary > p1.Salary
order by
    p2.Salary;

-- Task - 3
select distinct
    f1.X AS X,
    f1.Y AS Y
from
    Functions f1
join
    Functions f2 on f1.X = f2.Y and f1.Y = f2.X
where
    f1.X < f1.Y
order by
    f1.X;

-- Task - 4
select
    c.contest_id,
    c.hacker_id,
    h.name,
    coalesce(sum(v.total_views), 0) as total_views,
    coalesce(sum(v.total_unique_views), 0) as total_unique_views,
    coalesce(sum(s.total_submissions), 0) as total_submissions,
    coalesce(sum(s.total_accepted_submissions), 0) as total_accepted_submissions
from
    contests c
join
    hackers h on c.hacker_id = h.hacker_id
join
    colleges co on c.contest_id = co.contest_id
join
    challenges ch on co.college_id = ch.college_id
left join
    view_stats v on ch.challenge_id = v.challenge_id
left join
    submission_stats s on ch.challenge_id = s.challenge_id
group by
    c.contest_id, c.hacker_id, h.name
having
    sum(v.total_views) > 0 or
    sum(v.total_unique_views) > 0 or
    sum(s.total_submissions) > 0 or
    sum(s.total_accepted_submissions) > 0
order by
    c.contest_id;

-- Task - 5
with daterange as (
    select date '2016-03-01' as submission_date
    union all
    select submission_date + interval '1' day
    from daterange
    where submission_date < date '2016-03-15'
),
dailysubmissions as (
    select
        dr.submission_date,
        s.hacker_id,
        count(s.submission_id) as submissions_count
    from
        daterange dr
    left join
        submissions s on dr.submission_date = s.submission_date
    group by
        dr.submission_date, s.hacker_id
),
uniquehackers as (
    select
        submission_date,
        count(distinct hacker_id) as unique_hackers
    from
        dailysubmissions
    group by
        submission_date
),
maxsubmissions as (
    select
        submission_date,
        hacker_id,
        submissions_count
    from (
        select
            submission_date,
            hacker_id,
            submissions_count,
            row_number() over (partition by submission_date order by submissions_count desc, hacker_id) as rn
        from
            dailysubmissions
    ) as ranked
    where
        rn = 1
)
select
    u.submission_date,
    u.unique_hackers,
    m.hacker_id,
    h.name,
    m.submissions_count
from
    uniquehackers u
join
    maxsubmissions m on u.submission_date = m.submission_date
join
    hackers h on m.hacker_id = h.hacker_id
order by
    u.submission_date;

 -- Task - 6
with points as (
    select
        min(lat_n) as min_lat,
        min(long_w) as min_long,
        max(lat_n) as max_lat,
        max(long_w) as max_long
    from
        station
)
select
    round(abs(min_lat - max_lat) + abs(min_long - max_long), 4) as manhattan_distance
from
    points;

-- Task - 7
with recursive numbers as (
    select 2 as num
    union all
    select num + 1
    from numbers
    where num < 1000
),
primenumbers as (
    select num
    from numbers
    where num not in (
        select n.num
        from numbers n
        join numbers m on m.num <= sqrt(n.num) and n.num % m.num = 0 and m.num > 1
    )
)
select string_agg(cast(num as varchar), '&') as prime_numbers
from primenumbers;

-- Task - 8
with occupationranks as (
    select
        name,
        occupation,
        row_number() over (partition by occupation order by name) as row_num
    from
        occupations
),
pivoted as (
    select
        max(case when occupation = 'doctor' then name end) as doctor,
        max(case when occupation = 'professor' then name end) as professor,
        max(case when occupation = 'singer' then name end) as singer,
        max(case when occupation = 'actor' then name end) as actor
    from
        occupationranks
    group by
        row_num
)
select
    doctor,
    professor,
    singer,
    actor
from
    pivoted;

-- Task - 9
with nodetype as (
    select
        n,
        p,
        case
            when p is null then 'Root'
            when n not in (select distinct p from bst) then 'Leaf'
            else 'Inner'
        end as node_type
    from
        bst
)
select
    n,
    node_type
from
    nodetype
order by
    n;

-- Task - 10
with employeecounts as (
    select
        company_code,
        count(distinct case when lead_manager_code is not null then lead_manager_code end) as lead_managers_count,
        count(distinct case when senior_manager_code is not null then senior_manager_code end) as senior_managers_count,
        count(distinct case when manager_code is not null then manager_code end) as managers_count,
        count(distinct employee_code) as total_employees_count
    from
        employee
    group by
        company_code
)
select
    c.company_code,
    c.founder,
    coalesce(ec.lead_managers_count, 0) as lead_managers_count,
    coalesce(ec.senior_managers_count, 0) as senior_managers_count,
    coalesce(ec.managers_count, 0) as managers_count,
    coalesce(ec.total_employees_count, 0) as total_employees_count
from
    company c
left join
    employeecounts ec on c.company_code = ec.company_code
order by
    c.company_code;

-- Task - 11
select distinct
    s.name
from
    students s
join
    friends f on s.id = f.id
join
    packages p1 on f.friend_id = p1.id
join
    packages p2 on s.id = p2.id
where
    p1.salary > p2.salary
order by
    p1.salary;

-- Task - 12
select
    jobfamily,
    country,
    sum(case when country = 'India' then cost else 0 end) as india_cost,
    sum(case when country = 'International' then cost else 0 end) as international_cost,
    (sum(case when country = 'India' then cost else 0 end) / nullif(sum(cost), 0)) * 100 as india_percentage,
    (sum(case when country = 'International' then cost else 0 end) / nullif(sum(cost), 0)) * 100 as international_percentage
from
    yourtable
group by
    jobfamily, country;

-- Task - 13
select bu, 
       month, 
       sum(cost) as total_cost, 
       sum(revenue) as total_revenue, 
       sum(cost) / nullif(sum(revenue), 0) as cost_revenue_ratio
from yourtable
group by bu, month;

-- Task - 14
select subband, 
       count(employeeid) as headcount, 
       (count(employeeid) / (select count(*) from yourtable)) * 100 as percentage_headcount
from yourtable
group by subband;

-- Task - 15
select employeeid, salary
from yourtable
fetch first 5 rows only;

-- Task - 16
update yourtable
set column1 = column2,
    column2 = column1;

--Task - 17
create login prakash with password = 'jyothiprakash@629';
use yourdatabasename;
create user balaji for login prakash;
alter role db_owner add member khizar;

-- Task - 18
select bu, 
       month, 
       sum(cost * employeecount) / sum(employeecount) as weighted_average_cost
from yourtable
group by bu, month;


-- Task - 19
select ceil(avg(salary) - avg(nullif(substr(salary, 1, length(salary) - 1), 0))) as salary_error
from yourtable;

-- Task - 20
insert into destination_table (column1, column2, ...)
select column1, column2, ...
from sourcet_able;
