/*

I'm gonna try something new with this one.
I'm gonna take an approach similar to that of the dispenser minigun attributes.
These attributes will be modular and almost fully customizable.
I'll even see if I can make the attributes gained per level customizable.
I'ma have fun with this!

Created by: Zethax
Document created on: February 25th, 2019
Last edit made on: February 26th, 2019
Current version: v1.0

Attributes in this pack:
	- "tanking grants upgrades"
		1) Base maximum charge needed to level up
		2) How much charge to add per level. Values above 1.0 are additive, values between 0 and 1 are multiplicative.
		3) Base damage resistance duration on level up
		4) Time to add per level up. Is additive
		5) Multiplier for damage dealt to charge
		6) Multiplier for damage taken to charge

*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <sdktools>
#include <cw3-attributes>
#include <zethax>
#include <tf2attributes>

#define PLUGIN_NAME "tf_custom_tank_goodness"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds in an attribute associated with a tanky Heavy minigun."
#define PLUGIN_VERS "v1.0"

#define SOUND_UPGRADE "weapons/vaccinator_charge_tier_04.wav"

#define TF_COND_DEFENSEBUFF_HIGH TFCond:45

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

public OnMapStart()
{
	PrecacheSound(SOUND_UPGRADE, true);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	SDKHook(client, SDKHook_PreThink, OnClientPreThink);
}

new bool:TankUpgrades[2049];
new Float:TankUpgrades_Charge[2049];
new Float:TankUpgrades_MaxCharge[2049];
new Float:TankUpgrades_AddPerLevel[2049];
new Float:TankUpgrades_DmgResistDur[2049];
new Float:TankUpgrades_AddDurPerLevel[2049];
new Float:TankUpgrades_DealtChargeRate[2049];
new Float:TankUpgrades_TakenChargeRate[2049];
new TankUpgrades_Level[2049];

new Float:LastTick[MAXPLAYERS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "tanking grants upgrades"))
	{
		new String:values[6][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		TankUpgrades_MaxCharge[weapon] = StringToFloat(values[0]);
		TankUpgrades_AddPerLevel[weapon] = StringToFloat(values[1]);
		TankUpgrades_DmgResistDur[weapon] = StringToFloat(values[2]);
		TankUpgrades_AddDurPerLevel[weapon] = StringToFloat(values[3]);
		TankUpgrades_DealtChargeRate[weapon] = StringToFloat(values[4]);
		TankUpgrades_TakenChargeRate[weapon] = StringToFloat(values[5]);
		
		TankUpgrades[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public Action:OnTakeDamageAlive(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if(attacker)
	{
		if(weapon > -1 && TankUpgrades[weapon] && TankUpgrades_Level[weapon] < 6)
		{
			TankUpgrades_Charge[weapon] += damage * TankUpgrades_DealtChargeRate[weapon];
		}
	}
	if(victim)
	{
		new wep = GetActiveWeapon(victim);
		if(wep > 0 && wep < 2049 && TankUpgrades[wep] && TankUpgrades_Level[wep] < 6)
		{
			TankUpgrades_Charge[wep] += damage * TankUpgrades_TakenChargeRate[wep];
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
	
	if(!TankUpgrades[weapon])
		return;
	
	if (GetEngineTime() >= LastTick[client] + 0.1)
		TankUpgrades_PreThink(client, weapon);
}

static void TankUpgrades_PreThink(client, weapon)
{
	if(TankUpgrades_Charge[weapon] >= TankUpgrades_MaxCharge[weapon] && TankUpgrades_Level[weapon] < 6)
	{
		TankUpgrades_Level[weapon]++;
		TankUpgrades_Charge[weapon] -= TankUpgrades_MaxCharge[weapon];
		if(TankUpgrades_AddPerLevel[weapon] > 1.0 || TankUpgrades_AddPerLevel[weapon] < -1.0)
			TankUpgrades_MaxCharge[weapon] += TankUpgrades_AddPerLevel[weapon];
		else
			TankUpgrades_MaxCharge[weapon] += TankUpgrades_MaxCharge[weapon] * TankUpgrades_AddPerLevel[weapon];
		
		switch(TankUpgrades_Level[weapon])
		{
			case 1: 
			{
				TF2Attrib_SetByName(weapon, "maxammo primary increased", 1.5);
			}
			case 2: 
			{
				TF2Attrib_SetByName(weapon, "heal on kill", 80.0);
			}
			case 3:
			{
				TF2Attrib_SetByName(weapon, "healing received bonus", 1.25);
				TF2Attrib_SetByName(weapon, "heal on kill", 64.0);
			}
			case 4:
			{
				TF2Attrib_SetByName(weapon, "damage force reduction", 0.5);
				TF2Attrib_SetByName(weapon, "airblast vulnerability multiplier hidden", 0.5);
			}
			case 5:
			{
				TF2Attrib_SetByName(weapon, "attack projectiles", 5.0);
			}
			case 6:
			{
				TF2Attrib_SetByName(weapon, "generate rage on damage", 3.0);
				TankUpgrades_Charge[weapon] = TankUpgrades_MaxCharge[weapon];
			}
		}
		
		TF2_AddCondition(client, TF_COND_DEFENSEBUFF_HIGH, TankUpgrades_DmgResistDur[weapon] + (TankUpgrades_AddDurPerLevel[weapon] * TankUpgrades_Level[weapon]));
		EmitSoundToAll(SOUND_UPGRADE, client);
	}
	
	SetHudTextParams(-1.0, 0.6, 0.2, 255, 255, 255, 255);
	ShowSyncHudText(client, hudText_Client, "Upgrade: [%i%%] | [100%%]\nLevel: [%i] | [6]", RoundFloat((TankUpgrades_Charge[weapon] / TankUpgrades_MaxCharge[weapon]) * 100.0), TankUpgrades_Level[weapon]);
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	TankUpgrades[ent] = false;
	TankUpgrades_Charge[ent] = 0.0;
	TankUpgrades_MaxCharge[ent] = 0.0;
	TankUpgrades_AddPerLevel[ent] = 0.0;
	TankUpgrades_DmgResistDur[ent] = 0.0;
	TankUpgrades_AddDurPerLevel[ent] = 0.0;
	TankUpgrades_DealtChargeRate[ent] = 0.0;
	TankUpgrades_TakenChargeRate[ent] = 0.0;
	TankUpgrades_Level[ent] = 0;
}
