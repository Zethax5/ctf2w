/*

Created by: Zethax
Document created on: January 15th, 2019
Last edit made on: January 15th, 2019
Current version: v0.0

Attributes in this pack:
 None so far

*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <cw3-attributes>
#include <zethax>

#define PLUGIN_NAME "tf_custom_kills_boost_weapon"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds custom attributes associated with minicrit boosting"
#define PLUGIN_VERS "v0.0"

public Plugin:my_info = {
  
  name        = PLUGIN_NAME,
  author      = PLUGIN_AUTH,
  description = PLUGIN_DESC,
  version     = PLUGIN_VERS,
  url         = ""
};

public OnPluginStart() {
 
 HookEvent("player_death", OnPlayerDeath);
 
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

new bool:KillsBoost[2049];
new Float:KillsBoost_MaxDur[2049];
new Float:KillsBoost_StoredDur[2049];
new Float:KillsBoost_GainOnKill[2049];
new Float:KillsBoost_GainOnMeleeKill[2049];
new KillsBoost_Condition[2049];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
  new Action:action;
  if(!StrEqual(plugin, "tf_custom_kills_boost_weapon"))
    return;
  
  new weapon = GetPlayerWeaponSlot(client, slot);
  if(weapon < 0 || weapon > 2048)
    return;
  
  if(StrEqual(attrib, "kills with other weapons boost this weapon"))
  {
    new String:values[4][10];
    ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
    
    KillsBoost_MaxDur[weapon]          = StringToFloat(values[0]);
    KillsBoost_GainOnKill[weapon]      = StringToFloat(values[1]);
    KillsBoost_GainOnMeleeKill[weapon] = StringToFloat(values[2]);
    KillsBoost_Condition[weapon]       = StringToInt(values[3]);
    
    KillBoost[weapon] = true;
    action = Plugin_Handled;
  }
  
  return action;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
  new victim = GetClientOfUserId(GetEventInt(event, "userid"));
  new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
  new weapon = GetActiveWeapon(attacker);
  
  if(attacker && victim &&
      weapon > 0 && weapon < 2049)
  {
    new primary = GetPlayerWeaponSlot(attacker, 0);
    if(primary > 0 && primary < 2049 && KillsBoost[primary])
    {
      if(weapon == GetPlayerWeaponSlot(attacker, 1))
      {
        KillsBoost_StoredDur[primary] += KillsBoost_GainOnKill[primary];
        if(KillsBoost_StoredDur[primary] > KillsBoost_MaxDur[primary])
          KillsBoost_StoredDur[primary] = KillsBoost_MaxDur[primary];
      }
      else if(weapon == GetPlayerWeaponSlot(attacker, 2))
      {
        KillsBoost_StoredDur[primary] += KillsBoost_GainOnMeleeKill[primary];
        if(KillsBoost_StoredDur[primary] > KillsBoost_MaxDur[primary])
          KillsBoost_StoredDur[primary] = KillsBoost_MaxDur[primary];
      }
    }
  }
}

public OnClientPreThink(client)
{
  if(!IsValidClient(client))
    return;
  
  new weapon = GetActiveWeapon(client);
  if(weapon < 0 || weapon > 2048)
    return;
  
  if(!KillsBoost[weapon])
    return;
  
  if(GetEngineTime() > LastTick[client] + 0.1)
    KillsBoost_PreThink(client, weapon);
}

static void KillsBoost_PreThink(client, weapon)
{
  if(TF2_IsPlayerInCondition(client, TFCond:0) && KillsBoost_StoredDur[weapon] > 0.0)
  {
    TF2_AddCondition(client, TFCond:KillsBoost_Condition[weapon], 0.2);
    KillsBoost_StoredDur[weapon] -= 0.1;
  }
  
  LastTick[client] = GetEngineTime();
}

public OnEntityDestroyed(ent)
{
  if(ent < 0 || ent > 2048)
    return;
  
  KillsBoost[ent] = false;
  KillsBoost_MaxDur[ent] = 0.0;
  KillsBoost_StoredDur[ent] = 0.0;
  KillsBoost_GainOnKill[ent] = 0.0;
  KillsBoost_GainOnMeleeKill[ent] = 0.0;
  KillsBoost_Condition[ent] = 0;
}
