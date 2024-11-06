# Term Project 1

Hello! Welcome to the World Cup Analysis Project, a comprehensive exploration of FIFA World Cup data. This project uses an extensive dataset to analyze World Cup tournament data, including detailed information on players, teams, matches, goals, and tournaments. The dataset captures various aspects of the World Cup, offering insights into historical performance, team and player statistics, achievements, and trends across tournaments.

The datasets used in this project are available in the "Term1" folder. These datasets were imported manually through MySQL's Table Import Data Wizard rather than through code. For this reason, I kindly ask you to import the data manually after creating the tables. For easier data import, the datasets were modified from their original formats, retaining only the columns necessary for the analysis.

The main purpose of this project was to create an operational and analytical data layer for World Cup data that will allow YOU, the user, to extract meaningful insights. This includes:

-- Organize the data into a relational model suitable for complex queries.
-- Support analysis through views, materialized views, and an ETL pipeline.
-- Provide a denormalized data structure for easier querying and reporting.

When approaching this project I was curious in finding out the win probability for each country in each tournament, examining team performance across regional confederations, and identifying the top goal-scorers among players. To address them, the following views and calculations were implemented:

-- Tournament Overview: This view provides a summary of each World Cup tournament, including the year, host country, winning team, number of teams, total matches, and total goals. It handles missing data by displaying "Data Missing" in place of NULL values, ensuring a comprehensive overview for each tournament.

-- Team Win Rate Analysis: A view that calculates the win percentage of each team based on their tournament performance, ordered by the highest win rate. This view gives insights into the historical performance of teams across different World Cups.

-- Top Scorers Analysis: A view that lists the top 10 goal scorers in World Cup history, detailing their total goals, position, and average goals per match. Players with missing data were handled to ensure clear and accurate representation.

-- Confederation Performance: This analysis calculates and summarizes each confederation's performance based on wins, losses, draws, goals scored, and goals conceded, providing an overview of regional performance trends.

You can find answers to these insights by running the code in MYSQL WorkBench that is provided in the Term 1 project. An ERD (Entity-Relationship Diagram) illustrating the relationships among tables is also included.

Thank you for your interest in this project! I hope these views and analyses answer your questions and provide valuable insights into World Cup tournament history and performance.
