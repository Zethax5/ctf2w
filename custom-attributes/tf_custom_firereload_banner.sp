/*

Created by: Zethax
Document created on: March 12th, 2019
Last edit made on: March 12th, 2019
Current version: v1.0

Attributes in this pack:
	-> "soldier buff is fire-reload"
		Any value activates
		
		Replaces buff banner with a fire/reload rate buff

*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <cw3-attributes>
#include <zethax>
#include <tf2attributes>

#define PLUGIN_NAME "tf_custom_firereload_banner"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds an attribute that grants fire rate and reload rate buffs"
#define PLUGIN_VERS "v1.0"

public Plugin:my_info = {
  
	name        = PLUGIN_NAME,
	author      = PLUGIN_AUTH,
	description = PLUGIN_DESC,
	version     = PLUGIN_VERS,
	url         = ""
};

public OnPluginStart() {
 	
 	HookEvent("deploy_buff_banner", OnDeployBuffBanner);
 	
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

new bool:FireReloadBanner[2049];

new bool:BuffDeployed[MAXPLAYERS + 1];
new bool:Buffed[MAXPLAYERS + 1];
new Float:LastTick[MAXPLAYERS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "soldier buff is fire-reload"))
	{
		FireReloadBanner[weapon] = true;
		
		TF2Attrib_SetByName(weapon, "mod soldier buff type", 1.0);
		TF2Attrib_SetByName(weapon, "kill eater score type", 51.0);
		action = Plugin_Handled;
	}
	
	return action;
}

public void OnDeployBuffBanner(Handle:event, const String:strname[], bool:dontBroadcast)
{
   new client = GetClientOfUserId(GetEventInt(event, "buff_owner"));
   BuffDeployed[client] = true;
}

public OnClientPreThink(client)
{
	if(!IsValidClient(client))
		return;
	
	if(Buffed[client])
		TF2_RemoveCondition(client, TFCond_Buffed);
	
	new weapon = GetPlayerWeaponSlot(client, 1);
	if(weapon < 0 || weapon > 2048)
		return;
	
	if(GetEngineTime() >= LastTick[client] + 0.1)
		FireReloadBanner_PreThink(client, weapon);
}

void FireReloadBanner_PreThink(client, weapon)
{
	if(Buffed[client])
		Buffed[client] = false;
	
	if(FireReloadBanner[weapon] && BuffDeployed[client])
	{
		new Float:ClientPos[3];
		GetClientAbsOrigin(client, ClientPos);
		new Float:TargetPos[3];
		for (new target = 1; target < MaxClients; target++)
		{
			if(IsValidClient(target) && GetClientTeam(target) == GetClientTeam(client))
			{
				GetClientAbsOrigin(target, TargetPos);
				
				new Float:distance = GetVectorDistance(ClientPos, TargetPos);
				new Float:buffRadius = 450.0;
				if(distance <= buffRadius)
				{
					Buffed[target] = true;
					TF2_AddCondition(target, TFCond:113);
				}
			}
		}
		
		if(GetRageMeter(client) < 0.1)
			BuffDeployed[client] = false;
	}
	
	LastTick[client] = GetEngineTime();
}

public OnEntityDestroyed(ent)
{
    if(ent < 0 || ent > 2048)
        return;
	
	FireReloadBanner[ent] = false;
}

stock Float:GetRageMeter(client)
{
	if(!IsValidClient(client))
		return -1.0;
	
	return GetEntPropFloat(client, Prop_Send, "m_flRageMeter");
}