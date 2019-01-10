/*

Created by: Zethax
Document created on: Wednesday, January 9th, 2019
Last edit made on: Thursday, January 10th, 2019
Current version: v0.0

Attributes in this pack:
  - "dispenser minigun main"
        1) Radius of the dispenser
        2) Maximum healing required to charge Dispensing Fury
        3) How long Dispensing Fury lasts
        
        The main attribute for the dispenser minigun attributes.
        This attribute is required for the others to work.
        Don't want Dispensing Fury? Set the values associated with it to 0 to disable.

  - "dispenser minigun heal"
        1) Heal rate in a percentage of max health
        
        Restores health to allies within the radius at a rate of X% of their max health per second.
        Requires "dispenser minigun main" to work.
        
  - "dispenser minigun ammo"
        1) Ammo dispensing rate in a percentage of max ammo pool
        
        Replenishes ammo to allies within the radius at a rate of X% of their max ammo per second.
        Requires "dispenser minigun main" to work.
  
*/

#pragma semicolon 1
#include <sourcemod>
#include <cw3-attributes>
#include <tf2>
#include <zethax>

#define PLUGIN_NAME "Dispenser Minigun"
#define PLUGIN_DESC "Creates the attributes associated with the dispenser minigun"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_VERS "v0.0"

#define SOUND_DISPENSE "weapons/dispenser_heal.wav"

public Plugin:my_info = {
  
  name        = PLUGIN_NAME,
  description = PLUGIN_DESC,
  author      = PLUGIN_AUTH,
  version     = PLUGIN_VERS,
  url         = ""
};

//These attributes were seen before, but were terribly made
//They put a heavy load on the server when in use
//So I'm just remaking them completely

public OnPluginStart() 
{

  for(new i = 1; i < MaxClients; i++)
  {
    if(!IsValidClient(i))
      continue;
    
    OnClientPutInServer(i);
  }
}

public OnClientPutInServer(client)
{
  SDKHook(client, SDKHook_PostThink, OnClientPostThink);
}

new bool:DispenserMinigun[2049];
new Float:DispenserMinigun_Radius[2049];
new Float:DispenserMinigun_Charge[2049];
new Float:DispenserMinigun_MaxCharge[2049];
new Float:DispenserMinigun_FuryDur[2049];
new bool:DispenserMinigun_InFury[2049];
new bool:DispenserMinigun_InRadius[MAXPLAYERS + 1];

new bool:DispenserMinigun_Heal[2049];
new Float:DispenserMinigun_HealRate[2049];

new bool:DispenserMinigun_Ammo[2049];
new Float:MinigunAmmo_DispenseRate[2049];

//Tracks last time a player performed a healing tick
//Used to reduce the load on the server heavily
new Float:LastTick[MAXPLAYERS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
  new Action:action;
  
  if(!StrEqual(plugin, "tf_custom_dispenser_minigun"))
    return action;
  
  new weapon = GetPlayerWeaponSlot(client, slot);
  if(weapon < 0 || weapon > 2048)
    return action;
  
  if(StrEqual(attrib, "dispenser minigun main"))
  {
    new String:values[3][10];
    ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
    
    DispenserMinigun_Radius[weapon] = StringToFloat(values[0]);
    DispenserMinigun_MaxCharge[weapon] = StringToFloat(values[1]);
    DispenserMinigun_FuryDur[weapon] = StringToFloat(values[2]);
    
    DispenserMinigun[weapon] = true;
    action = Plugin_Handled;
  }
  
  //The following attributes require "dispenser minigun main" to be present on the weapon with defined values
  //or else they simply won't work.
  
  else if(StrEqual(attrib, "dispenser minigun heal") && DispenserMinigun[weapon])
  {
    DispenserMinigun_HealRate[weapon] = StringToFloat(value);
    
    DispenserMinigun_Heal[weapon] = true;
    action = Plugin_Handled;
  }
  else if(StrEqual(attrib, "dispenser minigun ammo") && DispenserMinigun[weapon])
  {
    DispenserMinigun_DispenseRate[weapon] = StringToFloat(value);
    
    DispenserMinigun_Ammo[weapon] = true;
    action = Plugin_Handled;
  }
  
  return action;
}

public void OnClientPostThink(client)
{
  if(!IsValidClient(client))
    return;
  
  new weapon = GetActiveWeapon(client);
  if(weapon < 0 || weapon > 2048)
    return;
  
  if(GetEngineTime() > LastTick[client] + 0.1 && DispenserMinigun[weapon])
    DispenserMinigun(client, weapon);
}

static void DispenserMinigun(client, weapon)
{
  new buttons = GetClientButtons(client);
  if((buttons & IN_ATTACK2) == IN_ATTACK2)
  {
    new Float:Pos1[3];
    GetClientAbsOrigin(client, Pos1);
    for(new i = 1; i < MaxClients; i++)
    {
      if(IsValidClient(i) && GetClientTeam(i) == GetClientTeam(client))
      {
        //Gets the position of the valid player in question
        new Float:Pos2[3];
        GetClientAbsOrigin(i, Pos2);
        
        //Gets the distance between the Heavy and the client
        new Float:distance = GetVectorDistance(Pos1, Pos2);
        
        //A check to remove InRadius
        //Used for sounds
        if(distance > DispenserMinigun_Radius[weapon] && DispenserMinigun_InRadius[i])
          DispenserMinigun_InRadius[i] = false;
        
        if(distance <= DispenserMinigun_Radius[weapon])
        {
          //Function that actually heals the player, because Sourcemod and TF2
          //don't provide such a library on their own
          if(DispenserMinigun_Heal[weapon])
            HealPlayer(i, client, RoundFloat(GetClientMaxHealth(i) * DispenserMinigun_HealRate[weapon]), _);
          
          //Creates a visual effect on players being healed, similar to the Amputator
          //A team colored ring at their feet
          TF2_AddCondition(i, TFCond:-1, 0.2, client);
          
          //Emits healing sound to players that step into the radius
          if(!DispenserMinigun_InRadius[i])
          {
            EmitSoundToAll(SOUND_DISPENSE, client);
            DispenserMinigun_InRadius[i] = true;
          }
        }
      }
    }
  }
}

public OnEntityDestroyed(ent)
{
  if(ent < 0 || ent > 2048)
    return;
    
  DispenserMinigun[ent] = false;
  DispenserMinigun_Radius[ent] = 0.0;
  DispenserMinigun_MaxCharge[ent] = 0.0;
  DispenserMinigun_Charge[ent] = 0.0;
  DispenserMinigun_FuryDur[ent] = 0.0;
  DispenserMinigun_InFury[ent] = false;
  
  DispenserMinigun_Heal[ent] = false;
  DispenserMinigun_HealRate[ent] = 0.0;
  
  DispenserMinigun_Ammo[ent] = false;
  DispenserMinigun_DispenseRate[ent] = 0.0;
}
