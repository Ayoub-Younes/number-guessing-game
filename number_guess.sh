#!/bin/bash
PSQL="psql -X --username=freecodecamp --dbname=number_guess --tuples-only -c"
echo "Enter your username:"
read USERNAME
GAME_INTRO(){
USER_RECORD=$($PSQL "SELECT best_game, games_played FROM usernames WHERE username = '$USERNAME'")
if [[ -z $USER_RECORD ]]
then
 echo "Welcome, $USERNAME! It looks like this is your first time here."
 INSERT_USER=$($PSQL "INSERT INTO usernames (username) VALUES ('$USERNAME')")
else
 echo "$USER_RECORD" | while read BEST_GAME BAR GAMES_PLAYED
 do
 echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
 done
fi
}
GAME_INTRO

USERNAME_ID=$($PSQL "SELECT user_id FROM usernames WHERE username='$USERNAME'")

#GAME START AND UPDATE
SECRET_NUMBER=$(($RANDOM % 1000 + 1))
#update played_games
UPDATE_GAMES_PLAYED=$($PSQL "UPDATE usernames SET games_played = $GAMES_PLAYED + 1 WHERE user_id = $USERNAME_ID")
INSERT_GAME=$($PSQL "INSERT INTO games (user_id) VALUES ($USERNAME_ID) RETURNING game_id")
GAME_ID=$($PSQL "SELECT game_id FROM games WHERE user_id =$USERNAME_ID ORDER BY game_id DESC LIMIT 1")
GUESS_GAME(){
 read GUESSED_NUMBER
 if [[ ! $GUESSED_NUMBER =~ ^[0-9]+$ ]]
 then
  GUESS_MESSAGE "That is not an integer, guess again:"
 else
  INSERT_GUESS=$($PSQL "INSERT INTO guess (game_id, guessed_number) VALUES ($GAME_ID, $GUESSED_NUMBER)")
  if [[ $GUESSED_NUMBER = $SECRET_NUMBER ]]
  then
   NUMBER_OF_GUESSES=$($PSQL "SELECT COUNT(*) FROM guess WHERE game_id = $GAME_ID")
   NUMBER_OF_GUESSES_FORMATTED=$(echo $NUMBER_OF_GUESSES | sed -E 's/ //g')
   #update games table
   UPDATE_GAMES=$($PSQL "UPDATE games SET number_of_guesses = $NUMBER_OF_GUESSES_FORMATTED WHERE game_id = $GAME_ID")
   #update usernames table
   BEST_GAME=$(echo $($PSQL "SELECT MIN(number_of_guesses) FROM games WHERE user_id = $USERNAME_ID") | sed -E 's/ //g')
   INSERT_BEST_GAME=$($PSQL "UPDATE usernames SET best_game = $BEST_GAME WHERE user_id = $USERNAME_ID")
   INSERT_RECORD=$($PSQL "INSERT INTO record (game_id, number_of_guesses) VALUES ($GAME_ID, $NUMBER_OF_GUESSES_FORMATTED)")
   echo "You guessed it in $NUMBER_OF_GUESSES_FORMATTED tries. The secret number was $SECRET_NUMBER. Nice job!"
  elif [[ $GUESSED_NUMBER > $SECRET_NUMBER ]]
   then
   GUESS_MESSAGE "It's lower than that, guess again:"
  else 
   GUESS_MESSAGE "It's higher than that, guess again:"
  fi 
 fi
}
GUESS_MESSAGE(){
 if [[ $1 ]] 
 then 
  echo $1
 else
  echo "Guess the secret number between 1 and 1000:"
 fi
 GUESS_GAME
}
GUESS_MESSAGE
