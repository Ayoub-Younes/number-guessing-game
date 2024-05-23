#!/bin/bash
PSQL="psql -X --username=freecodecamp --dbname=number_guess --tuples-only -c"

INTRO(){
echo "Enter your username:"
read USERNAME
USERNAME_ID=$($PSQL "SELECT user_id FROM usernames WHERE username='$USERNAME'")
if [[ -z $USERNAME_ID ]]
then
 echo "Welcome, $USERNAME! It looks like this is your first time here."
 INSERT_USER=$($PSQL "INSERT INTO usernames (username) VALUES ('$USERNAME')")
else
 RECORD=$($PSQL "SELECT best_game, games_played FROM record WHERE user_id=$USERNAME_ID")
 read -r BEST_GAME BAR GAMES_PLAYED <<< $RECORD
 echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

#GAME START
SECRET_NUMBER=$(($RANDOM % 1000 + 1))
echo $SECRET_NUMBER
USERNAME_ID=$($PSQL "SELECT user_id FROM usernames WHERE username='$USERNAME'")
NUMBER_OF_GUESSES=0
echo "Guess the secret number between 1 and 1000:"
}

INPUT(){
 read GUESSED_NUMBER
 VERIFY
}
VERIFY(){
if [[ ! $GUESSED_NUMBER =~ ^[0-9]+$ ]]
then
 echo "That is not an integer, guess again:"
 INPUT
else
 NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES+1))
 TEST
fi
}

TEST(){
 if [[ $GUESSED_NUMBER > $SECRET_NUMBER ]]
 then
  echo "It's lower than that, guess again:"
  INPUT
 elif [[ $GUESSED_NUMBER < $SECRET_NUMBER ]]
 then
  echo "It's higher than that, guess again:"
  INPUT
 elif [[ $GUESSED_NUMBER = $SECRET_NUMBER ]]
 then
  END
 fi
}

END(){
echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
#update record table
BEST_GAME=$($PSQL "SELECT best_game FROM record WHERE user_id=$USERNAME_ID")
if [[ -z $BEST_GAME ]]
then
 GAMES_PLAYED=1
 BEST_GAME=$NUMBER_OF_GUESSES
 INSERT_RECORD=$($PSQL "INSERT INTO record (user_id, best_game, games_played) VALUES ($USERNAME_ID, $BEST_GAME, $GAMES_PLAYED)")
else
 BEST_GAME=$(( $BEST_GAME < $NUMBER_OF_GUESSES ? $BEST_GAME: $NUMBER_OF_GUESSES ))
 UPDATE_RECORD1=$($PSQL "UPDATE record SET games_played = games_played + 1 WHERE user_id= $USERNAME_ID")
 UPDATE_RECORD2=$($PSQL "UPDATE record SET best_game = $BEST_GAME WHERE user_id= $USERNAME_ID")
fi
}
INTRO
INPUT
