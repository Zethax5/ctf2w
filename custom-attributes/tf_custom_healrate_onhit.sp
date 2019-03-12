/*

Created by: Zethax
Document created on: January 11th, 2019
Last edit made on: January 11th, 2019
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
#include <cw3-attributes>
#include <zethax>
#include <tf2attributes>

#define PLUGIN_NAME "tf_custom_healrate_onhit"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds an attribute that increases heal rate on hit"
#define PLUGIN_VERS "v0.0"

new Handle:hudText_Client;

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
	
	hudText_Client = CreateHudSynchronizer();
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
	SDKHook(client, SDKHook_PreThink, OnClientPreThink);
	SDKHook(client, SDKHook_PostThinkPost, OnClientPostThink);
}

new bool:HealRateOnHit[2049];
new Float:HealRateOnHit_Mult[2049];
new HealRateOnHit_MaxStacks[2049];
new HealRateOnHit_Stacks[2049];
new Float:HealRateOnHit_DrainDelay[2049];
new Float:HealRateOnHit_Delay[2049];
new HealRateOnHit_OldStacks[2049];

//made for testing purposes
//is not intended to actually get used
new GodHeavy[MAXPLAYERS + 1];

new Float:LastTick[MAXPLAYERS + 1];
//new UpdatePatient[MAXPLAYERS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "heal rate on hit"))
	{
		new String:values[3][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		HealRateOnHit_Mult[weapon] = StringToFloat(values[0]);
		HealRateOnHit_MaxStacks[weapon] = StringToInt(values[1]);
		HealRateOnHit_DrainDelay[weapon] = StringToFloat(values[2]);
		
		HealRateOnHit[weapon] = true;
		action = Plugin_Handled;
	}
	
	//meant for testing attribute above, not actually meant to be used
	else if(StrEqual(attrib, "god heavy"))
	{
		TF2Attrib_SetByName(weapon, "max health additive bonus", StringToFloat(value));
		GodHeavy[client] = StringToInt(value);
		action = Plugin_Handled;
	}
	
	return action;
}

public OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype, weapon, const Float:damageForce[3], const Float:damagePosition[3])
{
	if(attacker)
	{
		if(weapon > -1 && HealRateOnHit[weapon])
		{
			HealRateOnHit_Stacks[weapon]++;
			if(HealRateOnHit_Stacks[weapon] > HealRateOnHit_MaxStacks[weapon])
				HealRateOnHit_Stacks[weapon] = HealRateOnHit_MaxStacks[weapon];
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
	
	if(GetEngineTime() >= LastTick[client] + 0.1)
		HealRateOnHit_PreThink(client, weapon);
}

public OnClientPostThink(client)
{
	if(!IsValidClient(client))
		return;
	
	new weapon = GetActiveWeapon(client);
	if(weapon < 0 || weapon > 2048)
		return;
	
	new secondary = GetPlayerWeaponSlot(client, 1);
	if(secondary < 0 || secondary > 2048)
		return;
	
	/*
	if(UpdatePatient[client] > -1 && weapon == secondary)
	{
		//PrintToChat(client, "Updating medigun patient");
		SetEntPropEnt(weapon, Prop_Send, "m_hHealingTarget", UpdatePatient[client]);
		UpdatePatient[client] = -1;
	}
	*/
}

void HealRateOnHit_PreThink(client, weapon)
{
	new secondary = GetPlayerWeaponSlot(client, 1);
	if(secondary < 0)
		return;
	
	new attribWeapon = GetPlayerWeaponSlot(client, 0);
	if(attribWeapon < 0 || !HealRateOnHit[attribWeapon])
		attribWeapon = GetPlayerWeaponSlot(client, 2);
	if(attribWeapon < 0 || !HealRateOnHit[attribWeapon])
		return;
	
	if(HealRateOnHit_OldStacks[attribWeapon] != HealRateOnHit_Stacks[attribWeapon])
	{
		TF2Attrib_SetByName(secondary, "heal rate penalty", 1.0 + (HealRateOnHit_Stacks[attribWeapon] * HealRateOnHit_Mult[attribWeapon]));
		HealRateOnHit_OldStacks[attribWeapon] = HealRateOnHit_Stacks[attribWeapon];
		/*
		all this doesn't work for updating medigun patient
		if(weapon == secondary)
		{
			new patient = GetMediGunPatient(client);
			if(patient > -1)
			{
				UpdatePatient[client] = patient;
				SetEntPropEnt(weapon, Prop_Send, "m_hHealingTarget", -1);
				new DataPack:pack;
				UpdatePatient[client] = CreateDataTimer(0.0, UpdateMedigunPatient, pack, TIMER_FLAG_NO_MAPCHANGE);
				pack.WriteCell(weapon);
				pack.WriteCell(patient);
				pack.WriteCell(client);
				
			}
		}
		*/
	}
	if(weapon == secondary)
	{
		new patient = GetMediGunPatient(client);
		new maxhealth;
		
		if(patient > -1)
		{
			maxhealth = GetClientMaxHealth(patient);
			if(GodHeavy[patient])
				maxhealth = GodHeavy[patient];
		}
		
		if(patient > -1 && GetClientHealth(patient) < maxhealth)
		{
			if(GetEngineTime() >= HealRateOnHit_Delay[attribWeapon] + HealRateOnHit_DrainDelay[attribWeapon] && HealRateOnHit_Stacks[attribWeapon] > 0)
			{
				HealRateOnHit_Stacks[attribWeapon]--;
				HealRateOnHit_Delay[attribWeapon] = GetEngineTime();
			}
		}
	}
	
	SetHudTextParams(0.8, 0.6, 0.2, 255, 255, 255, 255);
	ShowSyncHudText(client, hudText_Client, "Bonus Heal Rate: %i%%", RoundFloat(HealRateOnHit_Stacks[attribWeapon] * HealRateOnHit_Mult[attribWeapon] * 100.0));
	
	LastTick[client] = GetEngineTime();
}

/*
public Action:UpdateMedigunPatient(Handle:timer, DataPack:pack)
{
	pack.Reset();
	new weapon = pack.ReadCell();
	new patient = pack.ReadCell();
	new client = pack.ReadCell();
	SetEntPropEnt(weapon, Prop_Send, "m_hHealingTarget", patient);
	UpdatePatient[client] = null;
}
*/

public OnEntityDestroyed(ent)
{
    if(ent < 0 || ent > 2048)
        return;
	
	HealRateOnHit[ent] = false;
	HealRateOnHit_Mult[ent] = 0.0;
	HealRateOnHit_Stacks[ent] = 0;
	HealRateOnHit_MaxStacks[ent] = 0;
	HealRateOnHit_OldStacks[ent] = 0;
	HealRateOnHit_DrainDelay[ent] = 0.0;
	HealRateOnHit_Delay[ent] = 0.0;
}
