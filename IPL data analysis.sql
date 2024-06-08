create database IPL;
use IPL;

-- ------------------------ Data Preparation ----------------------------
/* If we see the unique team1 names from the matches table, we will notice that there are two entries for Rising Pune Supergiant.
	one is Rising Pune Supergiant and another is with Rising Pune Supergiants. 
	Our task is to replace 'Rising Pune Supergiants' with 'Rising Pune Supergiant' in every column that contains the team name. */
select distinct team1
from matches;    

UPDATE deliveries
SET batting_team = "Rising Pune Supergiant"
WHERE batting_team = "Rising Pune Supergiants";

UPDATE deliveries
SET bowling_team = "Rising Pune Supergiant"
WHERE bowling_team = "Rising Pune Supergiants";

UPDATE matches
SET 
    team1 = CASE
        WHEN team1 = 'Rising Pune Supergiants' THEN 'Rising Pune Supergiant'
        ELSE team1
    END,
    team2 = CASE
        WHEN team2 = 'Rising Pune Supergiants' THEN 'Rising Pune Supergiant'
        ELSE team2
    END,
    toss_winner = CASE
        WHEN toss_winner = 'Rising Pune Supergiants' THEN 'Rising Pune Supergiant'
        ELSE toss_winner
    END,
    winner = CASE
        WHEN winner = 'Rising Pune Supergiants' THEN 'Rising Pune Supergiant'
        ELSE winner
    END
WHERE 
    team1 = 'Rising Pune Supergiants' 
    OR team2 = 'Rising Pune Supergiants'
    OR toss_winner = 'Rising Pune Supergiants'
    OR winner = 'Rising Pune Supergiants';
    
-- ******************** Some basic Analysis ********************
-- Fetch data of all the matches played on 15th May 2016.
select *
from matches
where str_to_date(date, "%d-%m-%Y") = "2016-05-15"; -- Similarly, we can fetch match details for any date.

-- Fetch data of all the matches where the margin of victory is more than 100 runs.
select *
from matches
where result_margin > 100;

-- Write a query to fetch the total number of dismissals by dismissal kinds.
select dismissal_kind, count(*) Total_boundary
from deliveries
where dismissal_kind <> "NA"
group by dismissal_kind;


-- ******************** Team Performance Analysis ********************
-- Total winning by each team in each season.
select year(ifnull(str_to_date(date, "%d-%m-%Y"), ifnull(str_to_date(date, "%d/%m/%Y"), 
		str_to_date(date, "%e/%c/%Y")))) as Year, 
		winner, count(*) as No_of_Win
from matches 
group by year, winner
order by year asc, No_of_Win desc;

-- Which team has won the most matches in each season?
with tempdf2 as(
				select *,  rank() over (partition by year order by No_of_Win desc) as rnk
				from (select year(ifnull(str_to_date(date, "%d-%m-%Y"), ifnull(str_to_date(date, "%d/%m/%Y"), 
								str_to_date(date, "%e/%c/%Y")))) as Year, 
								winner, count(*) as No_of_Win
						from matches 
						group by year, winner
						order by year asc) as tempdf)

select year, winner, No_of_Win
from tempdf2
where rnk=1;

-- Which team has the highest number of championship wins?
select winner, count(*) No_of_champion
from matches
where ifnull(str_to_date(date, "%d-%m-%Y"), ifnull(str_to_date(date, "%d/%m/%Y"), 
		str_to_date(date, "%e/%c/%Y"))) in (
											select Final_match_date
											from ( select year(ifnull(str_to_date(date, "%d-%m-%Y"), ifnull(str_to_date(date, "%d/%m/%Y"), 
																					str_to_date(date, "%e/%c/%Y")))) as Year, 
															max(ifnull(str_to_date(date, "%d-%m-%Y"), ifnull(str_to_date(date, "%d/%m/%Y"), 
																					str_to_date(date, "%e/%c/%Y")))) as Final_match_date
													from matches
													group by year) as tempdf)
group by winner
order by No_of_champion desc
limit 1;


-- ******************** Player Performance Insights ********************
-- Who are the top 10 run-scorers in IPL history?
select batsman, sum(batsman_runs) as TotalRunScore
from deliveries
group by batsman
order by 2 desc
limit 10;

-- Who are the top 10 wicket-takers in IPL history?
select distinct(dismissal_kind)
from deliveries;

select bowler, sum(is_wicket) as TotalWicket
from deliveries
where dismissal_kind not in ('run out', 'retired hurt', 'obstructing the field')
group by bowler
order by 2 desc
limit 10;

-- Most dot balls bowled by a Player
select bowler, count(*) as Total_dot_ball
from deliveries
where total_runs=0
group by bowler
order by 2 desc;

-- Most dot balls Played by a Player
select batsman, count(*) as Total_dot_ball
from deliveries
where batsman_runs=0
group by batsman
order by 2 desc;

-- Write a query to get the top 5 bowlers who conceded maximum extra runs
select bowler, sum(extra_runs) as Extra_Runs
from deliveries
group by bowler
order by Extra_Runs desc
limit 5;


-- ******************** Match Analysis ********************
-- Number of matchs tied in each season?
select year(ifnull(str_to_date(date, "%d-%m-%Y"), ifnull(str_to_date(date, "%d/%m/%Y"), 
				str_to_date(date, "%e/%c/%Y")))) as Year, count(*) as No_of_Tie
from matches
where result = 'tie'
group by Year;

-- How many matches were won by teams batting first vs. teams batting second?
select winner as Team, count(*) win_batting_first
from matches
where (toss_winner=winner and toss_decision='bat') or (toss_winner<>winner and toss_decision='bat') and winner<> 'NA'
group by Team
order by Team; -- Batting first

select winner as Team, count(*) win_batting_second
from matches
where (toss_winner=winner and toss_decision='field') or (toss_winner<>winner and toss_decision='field') and winner<> 'NA'
group by Team
order by Team; -- Batting second


-- ******************** Venue Analysis ********************
-- Which venues have hosted the most matches?
select venue, count(*) as No_of_match_hosted
from matches
group by venue
order by 2 desc
limit 1;

-- What is the average score in a match at each venue?
with tempdf2 as(
				select venue, ifnull(str_to_date(date, "%d-%m-%Y"), 
									ifnull(str_to_date(date, "%d/%m/%Y"), str_to_date(date, "%e/%c/%Y"))) as Date, sum(total_runs) as Total_Run
				from (select m.venue, m.date, d.total_runs
						from matches m right join deliveries d on m.id=d.id) as tempdf
				group by venue, Date
				order by venue, date)

select venue, round(avg(Total_Run),0) average_score
from tempdf2
group by venue;

-- Write a query to fetch the year-wise total runs scored at Eden Gardens and order it in the descending order of total runs scored.
select year(ifnull(str_to_date(date, "%d-%m-%Y"), ifnull(str_to_date(date, "%d/%m/%Y"), 
				str_to_date(date, "%e/%c/%Y")))) as Year, sum(total_runs) as Total_Run
from (select m.venue, m.date, d.total_runs
	from matches m right join deliveries d on m.id=d.id) as tempdf
where venue='Eden Gardens'
group by year
order by 2 desc;


-- ******************** Seasonal Trends ********************
-- What is the trend in the number of sixes and fours hit per season?
with four as(
			select year(ifnull(str_to_date(date, "%d-%m-%Y"), ifnull(str_to_date(date, "%d/%m/%Y"), 
						str_to_date(date, "%e/%c/%Y")))) as season, count(*) No_of_four
			from (select m.date, d.batsman_runs, d.batting_team
					from matches m right join deliveries d on m.id=d.id) as tempdf
			where batsman_runs = 4
			group by season),
	six as(
			select year(ifnull(str_to_date(date, "%d-%m-%Y"), ifnull(str_to_date(date, "%d/%m/%Y"), 
						str_to_date(date, "%e/%c/%Y")))) as season, count(*) No_of_six
			from (select m.date, d.batsman_runs, d.batting_team
					from matches m right join deliveries d on m.id=d.id) as tempdf
			where batsman_runs = 6
			group by season)

select f.season, No_of_four, No_of_six
from four f inner join six s using(season);


-- ******************** Economy and Strike Rates ********************
-- Which bowlers have the best economy rates?
with bowler_economy_rates as(
						select ifnull(str_to_date(date, "%d-%m-%Y"), ifnull(str_to_date(date, "%d/%m/%Y"), str_to_date(date, "%e/%c/%Y"))) as date,
								overs, bowler, sum(total_runs) as runs
						from (select m.date, d.overs, d.bowler, d.total_runs
											from matches m right join deliveries d on m.id=d.id) as tempdf
						group by date, overs, bowler)
        
select bowler, sum(runs)/count(*) as economy_rates
from bowler_economy_rates
group by bowler
order by 2;

-- Which batsmen have the best strike rates?
select batsman, round((sum(batsman_runs)/count(*))*100,2) as strike_rates
from deliveries
group by batsman
order by strike_rates desc;


-- ******************** Impact Players ********************
-- Who are the most impactful players based on performance metrics like Player of the Match awards?
select player_of_match, count(*) as No_of_PlayerOfTheMatch
from matches
group by player_of_match
order by 2 desc;
