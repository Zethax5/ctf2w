/*

Creator: Zethax
Document created on: Tuesday, December 18th, 2018
Last edit made: Tuesday, December 18th, 2018
Current Version: v0.1

Functionality:
Allows the Machina to take a percentage of overkill damage and add that to the next shot.
Overkill damage will not stack on itself.
Overkill damage is defined as "the difference in damage and the victim's health before death."

*/

#pragma semicolon         1
#include                  <sourcemod>
#include                  <tf2>

#define PLUGIN_AUTHOR     "Zethax"
#define PLUGIN_NAME       "Machina Overkill Attribute"
#define PLUGIN_DESC       "Allows the Machina to use overkill damage on successive shots"
#define PLUGIN_VERSION    "v0.1"

public Plugin:my_info = {
  name        =   PLUGIN_NAME,
  author      =   PLUGIN_AUTHOR,
  description =   PLUGIN_DESC,
  version     =   PLUGIN_VERSION,
  url         =   ""
};

//Runs when the plugin starts
//Used to hook events such as player death and damage taken
public OnPluginStart() 
{
  HookEvent("player_death", Event_Death);
  
  for(new i = 1; i <= MaxClients; i++)
  {
    if(IsValidClient(i))
    {
      OnClientPutInServer(i);
    }
  }
}

//Called when the client enters a server
public OnClientPutInServer(client)
{
  SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

//Used to keep track of the damage that was dealt without the overkill damage multiplier
float OriginalDamage[MAXPLAYERS + 1];

//Keeps track of the overkill damage multiplier
float Overkill_Mult[2049];

//Stores the health of the victim
//Though, TF2 is weird and stores it as an int, making damage calculations complicated
int Overkill_EnemyHealth[2049];

//Tracks whether the user has used their power shot
int Overkill_Shot[2049];

//That's all the public variables we'll be using for this.


