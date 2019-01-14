/*

Created by: Zethax
Document created on: January 14th, 2019
Last edit made on: January 14th, 2019
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

#define PLUGIN_NAME "tf_custom_evasion_meter"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds custom attributes associated with the evasion meter"
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
  SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

new bool:EvasionMeter[2049];
new Float:EvasionMeter_Gain[2049];
new Float:EvasionMeter_Subtract[2049];
new Float:EvasionMeter_SubtractMelee[2049];
new Float:EvasionMeter_Charge[2049];
new Float:EvasionMeter_Drain[2049];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
  new Action:action;
  
  if(!StrEqual(plugin, "tf_custom_evasion_meter"))
    return action;
  
  new weapon = GetPlayerWeaponSlot(client, slot);
  if(weapon < 0 || weapon > 2048)
    return action;
  
  if(StrEqual(attrib, "gain evasion on hit"))
  {
    new String:values[4][10];
    ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
    
    EvasionMeter_Gain[weapon] = StringToFloat(values[0]);
    EvasionMeter_Subtract[weapon] = StringToFloat(values[1]);
    EvasionMeter_SubtractMelee[weapon] = StringToFloat(values[2]);
    EvasionMeter_Drain[weapon] = StringToFloat(values[3]);
    
    EvasionMeter[weapon] = true;
    action = Plugin_Handled;
  }
  
  return action;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damageCustom)
{
  new Action:action;
  if(attacker && victim)
  {
    if(EvasionMeter[weapon])
    {
      EvasionMeter_Charge[weapon] += EvasionMeter_Gain[weapon];
      if(EvasionMeter_Charge[weapon] > 1.0)
        EvasionMeter_Charge[weapon] = 1.0;
    }
    if(EvasionMeter[GetActiveWeapon(victim)])
    {
      new wep = GetActiveWeapon(victim);
      if(EvasionMeter_Charge[wep] >= RandomFloat(0.0, 1.0))
      {
        new Float:drain = EvasionMeter_Subtract[wep];
        if(weapon == GetPlayerWeaponSlot(attacker, 2)
          drain = EvasionMeter_SubtractMelee[wep];
        
        EvasionMeter_Charge[wep] -= damage / drain / 100.0;
        damage = 0.0;
        action = Plugin_Changed;
      } 
    }
  }
  return action;
}

public void OnClientPreThink(client)
{
  if(!IsValidClient(client))
    return;
  
  new weapon = GetActiveWeapon(client);
  if(weapon < 0 || weapon > 2048)
    return;
  
  if(!EvasionMeter[weapon])
    return;
  
  if(GetEngineTime() > LastTick[client] + 0.1)
    EvasionMeter_PreThink(client, weapon);
}

static void EvasionMeter_PreThink(client, weapon);
{
  if(EvasionMeter_Charge[weapon] > 0.0 && EvasionMeter_Drain[weapon] > 0.0)
  {
    EvasionMeter_Charge[weapon] -= EvasionMeter_Drain[weapon] / 0.1;
    if(EvasionMeter_Charge[weapon] < 0.0)
      EvasionMeter_Charge[weapon] = 0.0;
  }
}

public OnEntityDestroyed(ent)
{
  if(ent < 0 || ent > 2048)
    return;
  
  EvasionMeter[ent] = false;
  EvasionMeter_Gain[ent] = 0.0;
  EvasionMeter_Subtract[ent] = 0.0;
  EvasionMeter_SubtractMelee[ent] = 0.0;
  EvasionMeter_Charge[ent] = 0.0;
  EvasionMeter_Drain[ent] = 0.0;
}
