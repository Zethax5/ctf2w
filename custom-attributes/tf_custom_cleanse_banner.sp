/*

Created by: Zethax
Document created on: Thursday, December 20th, 2018
Last edit made on: Thursday, January 3rd, 2019
Current version: v0.1

Attributes in this pack:
  None so far

*/

#pragma semicolon 1
#include <sourcemod>
#include <cw3-attributes>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <zethax>
#include <tf2attributes>

#define PLUGIN_AUTHOR  "Zethax"
#define PLUGIN_DESC    "All custom attributes for custom Soldier weapons on the cTF2w server."
#define PLUGIN_NAME    "Cleanse Banner"
#define PLUGIN_VERS    "v0.1"

public Plugin:my_info = {
  
  name        = PLUGIN_NAME,
  author      = PLUGIN_AUTHOR,
  description = PLUGIN_DESC,
  version     = PLUGIN_VERS,
  url         = ""
};

public OnPluginStart() {
  
  HookEvent("deploy_buff_banner", OnDeployBuffBanner);
  
  for (new i = 1; i < MaxClients; i++)
  {
    if(!IsValidClient(i))
      continue;
      
    OnClientPutInServer(i);
  }
}

public OnClientPutInServer(client) {
  
  SDKHook(client, SDKHook_PostThink, OnClientPostThink);
}

//Used to track whether or not a player has deployed a custom buff banner
new bool:BuffDeployed[MAXPLAYERS + 1];

new bool:CleanseBanner[2049];
new Float:CleanseBanner_DebuffRed[2049];
new CleanseBanner_Healing[2049];
new CleanseBanner_NumPlayers[2049];
new bool:CleanseBanner_ToHeal[MAXPLAYERS + 1];
new CleanseBanner_Healer[MAXPLAYERS + 1];
new CleanseBanner_Delay[2049];
new bool:BuffRemoved[2049];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
  if(!StrEqual(plugin, "tf_custom_cleanse_banner"))
    return Plugin_Continue;
  
  new Action:action;
  new weapon = GetPlayerWeaponSlot(client, slot);
  
  if(weapon < 0 || weapon > 2049)
    return Plugin_Continue;
    
  if(StrEqual(attrib, "soldier buff is cleanse"))
  {
      new String:values[2][10];
      ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
      
      CleanseBanner_DebuffRed[weapon] = StringToFloat(values[0]);
      CleanseBanner_Healing[weapon] = StringToInt(values[1]);
      
      //Enables the rage meter and what not
      TF2Attrib_SetByName(weapon, "mod soldier buff type", 1.0);
      TF2Attrib_SetByName(weapon, "kill eater score type", 51.0);
      
      CleanseBanner[weapon] = true;
      action = Plugin_Handled;
  }
    
  return action;
}

public OnClientPostThink(client)
{	
	//Because of the way custom buff banners work, this needs to be put in place
	//The system only applies the effects 5 times per second
	//This is to keep the system from getting overloaded
	if(CleanseBanner_Delay[client] > GetEngineTime() + 0.2)
	CleanseBanner_PostThink(client);
}

public void OnDeployBuffBanner(Handle:event, const String:strname[], bool:dontBroadcast)
{
  new client = GetClientOfUserId(GetEventInt(event, "buff_owner"));
  if(IsValidClient(client))
  {
    BuffDeployed[client] = true;
  }
  
  if(GetEntPropFloat(client, Prop_Send, "m_flRageMeter") <= 0.1)
    BuffDeployed[client] = false;
}

static void CleanseBanner_PostThink(client)
{
	if(!IsValidClient(client))
		return;
  
	new banner = GetPlayerWeaponSlot(client, 1);
  	
  	
  		TF2Attrib_SetByName(weapon, "mod soldier buff type", 420.0);
  	
	CleanseBanner_NumPlayers[banner] = 0;
	if(CleanseBanner[banner] && BuffDeployed[client])
	{
		new team = GetClientTeam(client);
		for (new i = 1; i <= MaxClients; i++)
		{
			new Float:Pos1[3];
			GetClientAbsOrigin(client, Pos1);
			if (IsValidClient(i) && GetClientTeam(i) == team)
			{
				new Float:Pos2[3];
				GetClientAbsOrigin(i, Pos2);
				new Float:distance = GetVectorDistance(Pos1, Pos2);
				if (distance <= 450.0)
				{
					//TF2_RemoveCondition(i, TFCond:16); No longer needed
					CleanseBanner_ToHeal[i] = true;
					CleanseBanner_Healer[i] = client;
					CleanseBanner_NumPlayers[banner]++;
					//Insert debuff reduction stuff here
				}
			}
		}
	}
	//Due to the way the healing works this is how it's done
	//System tallies up all players in the radius and marks the to be healed
	//Later, the system will apply the healing after all the players have been tallied up
	if(CleanseBanner_ToHeal[client])
	{
		new healer = CleanseBanner_Healer[client];
		if(IsValidClient(healer))
		{
			new banner = GetPlayerWeaponSlot(healer, 1);
			if(banner > 0 && banner < 2049 && CleanseBanner[banner])
			{
				HealPlayer(healer, client, CleanseBanner_Healing[banner] * CleanseBanner_NumPlayers[banner], _);
				CleanseBanner_ToHeal[client] = false;
				CleanseBanner_Healer[client] = -1;
			}
		}
	}
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	CleanseBanner[ent] = false;
	CleanseBanner_NumPlayer[ent] = 0;
	CleanseBanner_DebuffRed[ent] = 0.0;
	CleanseBanner_Healing[ent] = 0;
}