#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

# Clear existing data (to prevent duplicates on re-run)
echo "$($PSQL "TRUNCATE games, teams RESTART IDENTITY;")"

echo "Inserting unique teams..."

# Extract unique team names from CSV and insert into the teams table
tail -n +2 games.csv | awk -F',' '{print $3; print $4}' | sort | uniq | while read TEAM
do
  # Insert team if not already present
  INSERT_TEAM_RESULT=$($PSQL "INSERT INTO teams(name) VALUES('$TEAM') ON CONFLICT (name) DO NOTHING;")
  if [[ $INSERT_TEAM_RESULT == "INSERT 0 1" ]]
  then
    echo "Inserted team: $TEAM"
  fi
done

echo "Inserting game data..."

# Read each game entry and insert it into the games table
tail -n +2 games.csv | while IFS=',' read YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS
do
  # Get team IDs
  WINNER_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$WINNER'")
  OPPONENT_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$OPPONENT'")

  # Insert game data
  INSERT_GAME_RESULT=$($PSQL "INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals) VALUES($YEAR, '$ROUND', $WINNER_ID, $OPPONENT_ID, $WINNER_GOALS, $OPPONENT_GOALS);")
  
  if [[ $INSERT_GAME_RESULT == "INSERT 0 1" ]]
  then
    echo "Inserted game: $YEAR $ROUND - $WINNER vs $OPPONENT ($WINNER_GOALS:$OPPONENT_GOALS)"
  fi
done

echo "Data import completed!"
