/*

Created by: Zethax
Document created on: Thursday, December 20th, 2018
Last edit made on: Saturday, March 12th, 2019
Current version: v0.9

Attributes in this pack:
	- "soldier buff is cleanse"
		1) Amount to heal per person per second
		2) Damage taken multiplier
		
		Deal damage to gain a buff banner.
		When full, use to grant yourself and nearby allies debuff immunity
		and X healing per second based on how many players are in the radius

*/

#pragma semicolon 1
#include <sourcemod>
#include <cw3-attributes>
#include <tf2_stocks>
#include <sdkhooks>
#include <sdktools>
#include <zethax>
#include <tf2attributes>
#include <tf_cond_info>

#define PLUGIN_AUTHOR  "Zethax"
#define PLUGIN_DESC    "Adds an attribute associated with a healing buff banner."
#define PLUGIN_NAME    "Cleanse Banner"
#define PLUGIN_VERS    "v0.9"

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
  
  SDKHook(client, SDKHook_PreThink, OnClientPreThink);
  //of course Crafting wants damage taken to charge this thing
  //ugh
  SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

//Used to track whether or not a player has deployed a custom buff banner
new bool:BuffDeployed[MAXPLAYERS + 1];

new bool:CleanseBanner[2049];
new Float:CleanseBanner_DmgTakenRage[2049];
new Float:CleanseBanner_DebuffRed[2049];
new CleanseBanner_Healing[2049];
new CleanseBanner_NumPlayers[2049];
new bool:CleanseBanner_ToHeal[MAXPLAYERS + 1];
new CleanseBanner_Healer[MAXPLAYERS + 1];

new Float:LastTick[MAXPLAYERS + 1];

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
      
      CleanseBanner_Healing[weapon] = StringToInt(values[0]);
      CleanseBanner_DmgTakenRage[weapon] = StringToFloat(values[1]);
      
      
      //Enables the rage meter and what not
      TF2Attrib_SetByName(weapon, "mod soldier buff type", 2.0);
      TF2Attrib_SetByName(weapon, "kill eater score type", 51.0);
      
      CleanseBanner[weapon] = true;
      action = Plugin_Handled;
  }
    
  return action;
}

public Action:OnTakeDamageAlive(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if(victim != attacker)
	{
		new secondary = GetPlayerWeaponSlot(victim, 1);
		if(secondary > -1 && CleanseBanner[secondary] && !BuffDeployed[victim])
		{
			new Float:rage = GetEntPropFloat(victim, Prop_Send, "m_flRageMeter");
			rage += (damage / 600.0) * (1.0 - CleanseBanner_DmgTakenRage[secondary]) * 100.0;
			if(rage > 100.0)
				rage = 100.0;
			SetEntPropFloat(victim, Prop_Send, "m_flRageMeter", rage);
		}
	}
}


public OnClientPreThink(client)
{	
	if(!IsValidClient(client))
		return;
	
	if(CleanseBanner_ToHeal[client])
		TF2_RemoveCondition(client, TFCond_Buffed);
	
	//Because of the way custom buff banners work, this needs to be put in place
	//The system only applies the effects 5 times per second
	//This is to keep the system from getting overloaded
	if(GetEngineTime() >= LastTick[client] + 0.2)
	{
		CleanseBanner_PreThink(client);
		LastTick[client] = GetEngineTime();
	}
}

public void OnDeployBuffBanner(Handle:event, const String:strname[], bool:dontBroadcast)
{
   new client = GetClientOfUserId(GetEventInt(event, "buff_owner"));
   BuffDeployed[client] = true;
}

void CleanseBanner_PreThink(client)
{
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
				new healing = CleanseBanner_Healing[banner] * CleanseBanner_NumPlayers[banner] / 5;
				HealPlayer(healer, client, healing, 1.0);
				CleanseBanner_ToHeal[client] = false;
				CleanseBanner_Healer[client] = -1;
				TF2_RemoveCondition(client, TFCond:26);
			}
		}
	}
	
	new banner = GetPlayerWeaponSlot(client, 1);
  	
  	if(banner < 0 || banner > 2048)
  		return;
  	
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
					TF2_RemoveCondition(i, TFCond_Buffed);
					TF2_AddCondition(i, TFCond:20, 0.25);
					CleanseBanner_ToHeal[i] = true;
					CleanseBanner_Healer[i] = client;
					CleanseBanner_NumPlayers[banner]++;
					
					TF2_RemoveCondition(i, TFCond_OnFire);
					TF2_RemoveCondition(i, TFCond_Jarated);
					TF2_RemoveCondition(i, TFCond_Milked);
					TF2_RemoveCondition(i, TFCond_MarkedForDeath);
					TF2_RemoveCondition(i, TFCond_MarkedForDeathSilent);
					TF2_RemoveCondition(i, TFCond_Gas);
					TF2_RemoveCondition(i, TFCond_Bleeding);
				}
			}
		}
	}
	
	if(GetEntPropFloat(client, Prop_Send, "m_flRageMeter") <= 0.1)
    	BuffDeployed[client] = false;
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	CleanseBanner[ent] = false;
	CleanseBanner_NumPlayers[ent] = 0;
	CleanseBanner_DebuffRed[ent] = 0.0;
	CleanseBanner_Healing[ent] = 0;
	CleanseBanner_DmgTakenRage[ent] = 0.0;
}
