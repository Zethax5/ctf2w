/*

Creator: Zethax
Document created on: Tuesday, December 18th, 2018
Last edit made: Tuesday, December 18th, 2018
Current Version: v0.2

Functionality:
Allows the Machina to take a percentage of overkill damage and add that to the next shot.
Overkill damage will not stack on itself.
Overkill damage is defined as "the difference in damage and the victim's health before death."

*/

#pragma semicolon         1
#include                  <sourcemod>
#include                  <zethax>
#include                  <tf2>

#define PLUGIN_AUTHOR     "Zethax"
#define PLUGIN_NAME       "Machina Overkill Attribute"
#define PLUGIN_DESC       "Allows the Machina to use overkill damage on successive shots"
#define PLUGIN_VERSION    "v0.2"

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
  //Used to detect when a player is killed by this weapon.
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
  //Used when multiplying damage dealt
  //Might not need this
  //SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
  
  //Used when calculating and adding additional damage
  SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

//Used to keep track of the damage that was dealt without the overkill damage multiplier
float OriginalDamage[MAXPLAYERS + 1];

//Keeps track of the overkill damage
float Overkill_Dmg[2049];
float Overkill_BonusDmg[2049];

//Stores the health of the victim
//Though, TF2 is weird and stores it as an int, making damage calculations complicated
int Overkill_EnemyHealth[2049];

//Tracks whether the user has used their power shot
int Overkill_Shot[2049];

//That's all the public variables we'll be using for this.


/*
===========================
|                         |
|   P R O C E S S I N G   |
|                         |
===========================
*/

//Here we track whether or not the player has fired their power shot, should one be stored.
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
  new Action:action;
  
  if(!IsValidClient(client)) return action;
  if (weapon < 0 || weapon > 2048)return action;
  
  //If a power shot is stored AND the weapon is the Machina.
  if(GetWeaponIndex(weapon) == 526 && Overkill_Shot[weapon] > 0)
    Overkill_Shot[weapon]--; //Tell the system the player has fired their power shot.
  
  return action;
}

//Here we calculate the damage that was actually dealt, in the instance that a shot was fired that dealt overkill damage.
//This is to prevent the overkill damage from stacking on itself, allowing the Sniper to essentially achieve godlike damage. 
//We also add bonus damage dealt onto the next shot
public Action:OnTakeDamageAlive(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
  new Action:action;
  
  if (!IsValidClient(attacker))return action;
	if (!IsValidClient(victim))return action;
	if (weapon < 0 || weapon > 2048)return action;
  
  //If the weapon used was the Machina
  if(GetWeaponIndex(weapon) == 526) //526 = Machina
  {
    //This is where we apply the bonus damage, should any be stored.
    if(Overkill_BonusDmg[weapon] > 1.0 && Overkill_Shot[weapon] > 0)
    {
      damage += Overkill_BonusDmg[weapon];
      action = Plugin_Changed;
    }
    
    /////////////////////////////////////////////////////////////////
    //This is where we calculate the damage that was originally dealt
    if(Overkill_BonusDmg[weapon] > 1.0) //If the weapon has overkill damage stored
    {
      //Stores the total damage dealt divided by the multiplier applied by Overkill damage.
      OriginalDamage[attacker]  = damage - Overkill_BonusDmg[weapon];
      Overkill_BonusDmg[weapon] = 0.0;
    }
    //Should the weapon not have stored overkill damage, just store raw damage
    else OriginalDamage[attacker] = damage;
    
    //Stores the unmodified damage for later use.
    Overkill_Dmg[weapon]          = OriginalDamage[attacker];
    
    //Stores the victim's health for later use
    Overkill_EnemyHealth[weapon]  = GetClientHealth(victim);
  }
  
  //Used later
  LastWeaponHurtWith[attacker] = weapon;
  
  return action;
}


//This is where the bonus damage that gets applied is actually calculated
public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
  //Defines who the victim and attacker are in variables
  new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
  
  //Takes the variable we used earlier to store the weapon damage was dealt with
  //Uses it here, because for some reason there's no way to track this in here normally
  new weapon = LastWeaponHurtWith[attacker];
  
  //If the weapon used to kill was the Machina
  if(GetWeaponIndex(weapon) == 526) //526 = Machina
  {
    //Here's where the bonus damage is actually calculated
    //Takes the original damage dealt and subtracts the victim's health from it
    //Then multiplies the result by a decimal, so we're not dealing a boatload of damage after headshotting a Scout at max charge
    Overkill_BonusDmg[weapon] = (Overkill_Dmg[weapon] - (float)Overkill_EnemyHealth[weapon]) * 0.15;
    
    //Telling the system that the player hasn't fired their new power shot
    Overkill_Shot[weapon] = 2; 
    
    //Sets the variables used to calculate bonus damage to 0
    Overkill_Dmg[weapon]        = 0.0;
    Overkill_EnemyHealth[weapon = 0;
  }
}

