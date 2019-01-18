/*

Created by: Zethax
Document created on: January 17th, 2019
Last edit made on: January 18th, 2019
Current version: v0.0

Attributes in this pack:
 None so far

*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <cw3_attributes>
#include <zethax>

#define PLUGIN_NAME "tf_custom_booster_uber"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds in a custom ubercharge"
#define PLUGIN_VERS "v0.0"

public Plugin:my_info = {
  
  name        = PLUGIN_NAME,
  author      = PLUGIN_AUTH,
  description = PLUGIN_DESC,
  version     = PLUGIN_VERS,
  url         = ""
};

public OnPluginStart() {
 
 for(new i = 1 ; i < MaxClients ; i++)
 {
  if(!IsValidClient(i))
   continue;
  
  OnClientPutInServer(i);
 }
}

public OnClientPutInServer(client)
{
  SDKHook(client, SDKHook_PreThink, OnClientPreThink);
}

new bool:BoosterUber[2049];
new Float:BoosterUber_Drain[2049];
new Float:BoosterUber_Overheal[2049];
new Float:BoosterUber_ShieldDur[2049];
new Float:BoosterUber_Dur[MAXPLAYERS + 1];
new Float:BoosterUber_Protection[2049];

new Float:LastTick[MAXPLAYERS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
  new Action:action;
  if(!StrEqual(plugin, PLUGIN_NAME))
    return;
  
  new weapon = GetPlayerWeaponSlot(client, slot);
  if(weapon < 0 || weapon > 2048)
    return;
  
  if(StrEqual(attrib, "ubercharge is booster shot"))
  {
    new String:values[4][10];
    ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
    
    BoosterUber_Drain[weapon] = StringToFloat(values[0]);
    BoosterUber_Overheal[weapon] = StringToFloat(values[1]);
    BoosterUber_ShieldDur[weapon] = StringToFloat(values[2]);
    BoosterUber_Protection[weapon] = StringToFloat(values[3]);
    
    BoosterUber[weapon] = true;
    action = Plugin_Handled;
  }
  
  return action;
}

public OnClientPreThink(client)
{
  if(!IsValidClient(client))
    return;
    
  new weapon = GetActiveWeapon(client);
  if(weapon < 0 || weapon > 2048)
    return;
  
  if(!BoosterUber[weapon])
    return;
  
  if(GetEngineTime() > LastTick[client] + 0.1)
    BoosterUber_PreThink(client, weapon);
}

static void BoosterUber_PreThink(client, weapon);
{
  new buttons = GetClientButtons(client);
  
  if((buttons & IN_ATTACK2) == IN_ATTACK2)
  {
    
  }
  
  LastTick[client] = GetEngineTime();
}

public OnEntityDestroyed(ent)
{
  if(ent < 0 || ent > 2048)
    return;
  
  BoosterUber[ent] = false;
  BoosterUber_Drain[ent] = 0.0;
  BoosterUber_Overheal[ent] = 0.0;
  BoosterUber_ShieldDur[ent] = 0.0;
  BoosterUber_Protection[ent] = 0.0;
}
