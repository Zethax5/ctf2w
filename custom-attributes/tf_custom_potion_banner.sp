/*

Created by: Zethax
Document created on: March 29th, 2019
Last edit made on: March 29th, 2019
Current version: v1.0

Attributes in this pack:
	-> "mod soldier buff is random spell"
		1) Amount of rage required to obtain 1 potion
		2) Maximum number of potions
		3) Buff duration
		
	-> "random spell list"
		1...10) Condition ID for "mod soldier buff is random spell" to choose from.
		NOTE: "mod soldier buff is random spell" has a default list it uses. This does not have to be applied.
		This is simply there for customization.

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

#define PLUGIN_NAME "tf_custom_potion_banner"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds an attribute which replaces the typical buff banner with a random buff for the user."
#define PLUGIN_VERS "v1.0"

new Handle:hudText_Rage;
new Handle:hudText_Potions;

public Plugin:my_info = {
  
	name        = PLUGIN_NAME,
	author      = PLUGIN_AUTH,
	description = PLUGIN_DESC,
	version     = PLUGIN_VERS,
	url         = ""
};

public OnPluginStart() {
 	
	HookEvent("deploy_buff_banner", OnBuffDeployed);

	
	for(new i = 1 ; i < MaxClients ; i++)
	{
		if(!IsValidClient(i))
			continue;
  
		OnClientPutInServer(i);
	}
	
	hudText_Rage = CreateHudSynchronizer();
	hudText_Potions = CreateHudSynchronizer();
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	SDKHook(client, SDKHook_PreThink, OnClientPreThink);
}

new bool:SpellBanner[2049];
new Float:SpellBanner_Duration[2049];
new Float:SpellBanner_Tick[2049];
new Float:SpellBanner_RageCap[2049];
new Float:SpellBanner_Rage[2049];
new SpellBanner_MaxPotions[2049];
new SpellBanner_Potions[2049];
new SpellBanner_Buffs[2049][10];

new Float:LastTick[MAXLAYERS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "mod soldier buff is random spell"))
	{
		new String:values[3][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		SpellBanner_RageCap[weapon] = StringToFloat(values[0]);
		SpellBanner_MaxPotions[weapon] = StringToInt(values[1]);
		SpellBanner_Duration[weapon] = StringToFloat(values[2]);
		
		//Sets default buffs
		SpellBanner_Buffs[weapon][0] = 90;
		SpellBanner_Buffs[weapon][1] = 91;
		SpellBanner_Buffs[weapon][2] = 92;
		SpellBanner_Buffs[weapon][3] = 93;
		SpellBanner_Buffs[weapon][4] = 94;
		SpellBanner_Buffs[weapon][5] = 95;
		SpellBanner_Buffs[weapon][6] = 96;
		SpellBanner_Buffs[weapon][7] = 97;
		SpellBanner_Buffs[weapon][8] = 103;
		SpellBanner_Buffs[weapon][9] = 109;
		
		//Enables rage meter
		TF2Attrib_SetByName(weapon, "mod soldier buff type", 1.0);
		TF2Attrib_SetByName(weapon, "kill eater score type", 51.0);
		
		SpellBanner[weapon] = true;
		action = Plugin_Handled;
	}
	else if(StrEqual(attrib, "random spell list"))
	{
		new String:values[10][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		for(new i = 0; i < 10; i++)
		{
			if(strlen(values[i]))
				SpellBanner_Buffs[weapon][i] = StringToInt(values[i]);
			else
				break;
			
		}
		
		action = Plugin_Handled;
	}
	
	return action;
}

public Action:OnTakeDamageAlive(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damageCustom)
{
	if(attacker && attacker != victim)
	{
		new secondary = GetPlayerWeaponSlot(attacker, 1);
		if(secondary > -1 && SpellBanner[secondary] && GetEngineTime() >= SpellBanner_Tick[secondary] + SpellBanner_Duration[secondary])
		{
			SpellBanner_Rage[secondary] += damage;
			if(SpellBanner_Rage[secondary] > SpellBanner_RageCap[secondary])
			{
				if(SpellBanner_Potions[secondary] < SpellBanner_MaxPotions[secondary])
				{
					SpellBanner_Rage[secondary] -= SpellBanner_RageCap[secondary];
					SpellBanner_Potions[secondary]++;
				}
				else
				{
					SpellBanner_Rage[secondary] = SpellBanner_RageCap[secondary];
				}
			}
		}
	}
}

public OnClientPreThink(client)
{
	if(!IsValidClient(client))
		return;
	
	new weapon = GetPlayerWeaponSlot(client, 1);
	if(weapon < 0 || weapon > 2048)
		return;
	
	if(!SpellBanner[weapon])
		return;
	
	if(GetEngineTime() >= LastTick[client] + 0.1)
	{
		if(SpellBanner_Charges[weapon] > 0 && GetEngineTime() >= SpellBanner_Tick[weapon] + SpellBanner_Duration[weapon])
			SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 100.0);
		else
			SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 0.0);
		
		//Displays rage
		SetHudTextParams(-1.0, 0.7, 0.2, 255, 255, 255, 255);
		ShowSyncHudText(client, hudText_Rage, "Rage: %i%% / 100%%", RoundFloat((SpellBanner_Rage[weapon] / SpellBanner_RageCap[weapon]) * 100.0));
		
		//Displays potions
		SetHudTextParams(-1.0, 0.6, 0.2, 255, 255, 255, 255);
		ShowSyncHudText(client, hudText_Potions, "Potions: %i / %i", SpellBanner_Potions[weapon], SpellBanner_MaxPotions[weapon]);
		
		LastTick[client] = GetEngineTime();
	}
}

public OnBuffDeployed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(client))
	{
		new weapon = GetPlayerWeaponSlot(client, 1);
		if(weapon > -1 && SpellBanner[weapon])
		{
			new choice = GetRandomInt(0, 9);
			TF2_AddCondition(client, TFCond:SpellBanner_Conds[weapon][choice], SpellBanner_Duration[weapon]);
			SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 0.0);
			
			SpellBanner_Potions[weapon]--;
			SpellBanner_Tick[weapon] = GetEngineTime();
		}
	}
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	new ClearConds[10] = { 0, ...};
	
	SpellBanner[ent] = false;
	SpellBanner_RageCap[ent] = 0.0;
	SpellBanner_Rage[ent] = 0.0;
	SpellBanner_MaxPotions[ent] = 0;
	SpellBanner_Potions[ent] = 0;
	SpellBanner_Duration[ent] = 0.0;
	SpellBanner_Buffs[ent] = ClearConds;
}
