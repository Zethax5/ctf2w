/*

Created by: Zethax
Document created on: February 27th, 2019
Last edit made on: April 23rd, 2019
Current version: v1.0

Attributes in this pack:
	- "turnabout ammo"
		1) Maximum amount of ammo the weapon is allowed to accumulate
		2) Amount of ammo gained on backstab (optional)
		3) Amount of ammo gained upon successfully sapping a building (optional)
		4) Amount of ammo gained on hit (optional)

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

#define PLUGIN_NAME "tf_custom_turnabout_ammo"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds an attribute that grants your primary weapon infinite ammo based on accuracy."
#define PLUGIN_VERS "v1.0"

public Plugin:my_info = {
  
	name        = PLUGIN_NAME,
	author      = PLUGIN_AUTH,
	description = PLUGIN_DESC,
	version     = PLUGIN_VERS,
	url         = ""
};

public OnPluginStart() {
 	
 	HookEvent("object_destroyed", OnBuildingDestroyed);
 	
	for(new i = 1 ; i < MaxClients ; i++)
	{
		if(!IsValidClient(i))
			continue;
  
		OnClientPutInServer(i);
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
	SDKHook(client, SDKHook_PostThink, OnClientPostThink);
}

new bool:TurnaboutAmmo[2049];
new TurnaboutAmmo_Max[2049];
new TurnaboutAmmo_GainOnHit[2049];
new TurnaboutAmmo_GainOnSap[2049];
new TurnaboutAmmo_GainOnBackstab[2049];
new TurnaboutAmmo_Ammo[2049];

new Float:LastTick[MAXPLAYERS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
		
	if(StrEqual(attrib, "turnabout ammo"))
	{
		new String:values[4][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		TurnaboutAmmo_Max[weapon] = StringToInt(values[0]);
		if(strlen(values[1]))
			TurnaboutAmmo_GainOnBackstab[weapon] = StringToInt(values[1]);
		if(strlen(values[2]))
			TurnaboutAmmo_GainOnSap[weapon] = StringToInt(values[2]);
		if(strlen(values[3]))
			TurnaboutAmmo_GainOnHit[weapon] = StringToInt(values[2]);
		else
			TurnaboutAmmo_GainOnHit[weapon] = 1;
		
		TF2Attrib_SetByName(weapon, "mod max primary clip override", -1.0);
		TF2Attrib_SetByName(weapon, "hidden secondary max ammo penalty", 0.0);
		SetClip_Weapon(weapon, TurnaboutAmmo_Max[weapon]);
		SetAmmo_Weapon(client, weapon, TurnaboutAmmo_Max[weapon]);
		
		TurnaboutAmmo_Ammo[weapon] = TurnaboutAmmo_Max[weapon];
		TurnaboutAmmo[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if(!TurnaboutAmmo[weapon])
		return Plugin_Continue;
	
	TurnaboutAmmo_Ammo[weapon] -= 1;
	
	return Plugin_Continue;
}

public Action:OnBuildingDestroyed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new building = GetEventInt(event, "index");
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new assister = GetClientOfUserId(GetEventInt(event, "assister"));
	if(IsValidEntity(building))
	{
		new HasSapper = GetEntProp(building, Prop_Send, "m_bHasSapper");
		if(HasSapper)
		{
			if(IsValidClient(attacker))
			{
				new weapon = GetPlayerWeaponSlot(attacker, 0);
				if(weapon > -1 && TurnaboutAmmo[weapon])
				{
					TurnaboutAmmo_Ammo[weapon] += TurnaboutAmmo_GainOnSap[weapon];
					if(TurnaboutAmmo_Ammo[weapon] > TurnaboutAmmo_Max[weapon])
						TurnaboutAmmo_Ammo[weapon] = TurnaboutAmmo_Max[weapon];
				}
			}
			if(IsValidClient(assister))
			{
				new weapon = GetPlayerWeaponSlot(assister, 0);
				if(weapon > -1 && TurnaboutAmmo[weapon])
				{
					TurnaboutAmmo_Ammo[weapon] += TurnaboutAmmo_GainOnSap[weapon];
					if(TurnaboutAmmo_Ammo[weapon] > TurnaboutAmmo_Max[weapon])
						TurnaboutAmmo_Ammo[weapon] = TurnaboutAmmo_Max[weapon];
				}
			}
		}
	}
}

public OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype, weapon, const Float:damageForce[3], const Float:damagePosition[3], damageCustom)
{
	if(attacker)
	{
		if(damageCustom == TF_CUSTOM_BACKSTAB)
		{
			new primary = GetPlayerWeaponSlot(attacker, 0);
			if(primary > -1 && TurnaboutAmmo[primary])
			{
				TurnaboutAmmo_Ammo[primary] += TurnaboutAmmo_GainOnBackstab[primary];
				if(TurnaboutAmmo_Ammo[primary] > TurnaboutAmmo_Max[primary])
					TurnaboutAmmo_Ammo[primary] = TurnaboutAmmo_Max[primary];
				
				SetClip_Weapon(primary, TurnaboutAmmo_Ammo[primary]);
				SetAmmo_Weapon(attacker, primary, TurnaboutAmmo_Ammo[primary]);
			}
		}
		if(weapon > -1 && TurnaboutAmmo[weapon])
		{
			TurnaboutAmmo_Ammo[weapon] += TurnaboutAmmo_GainOnHit[weapon];
		}
		LastWeaponHurtWith[attacker] = weapon;
	}
}

public Action:OnTakeDamage_Building(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (attacker < 0 || attacker > MaxClients) return Plugin_Continue;
	if (weapon > -1)
	{
		if (TurnaboutAmmo[weapon])
		{
			TurnaboutAmmo_Ammo[weapon]++;
			if(TurnaboutAmmo_Ammo[weapon] > TurnaboutAmmo_Max[weapon])
				TurnaboutAmmo_Ammo[weapon] = TurnaboutAmmo_Max[weapon];
			
			SetClip_Weapon(weapon, TurnaboutAmmo_Ammo[weapon]);
			SetAmmo_Weapon(attacker, weapon, TurnaboutAmmo_Ammo[weapon]);
		}
	}
	return Plugin_Continue;
}

public OnClientPostThink(client)
{
	if(!IsValidClient(client))
		return;
	
	new weapon = GetActiveWeapon(client);
	if(!IsValidEdict(weapon))
		return;
	
	if(!TurnaboutAmmo[weapon])
		return;
	
	if(GetEngineTime() >= LastTick[client] + 0.1)
		TurnaboutAmmo_PostThink(client, weapon);
}

void TurnaboutAmmo_PostThink(client, weapon)
{
	if(TurnaboutAmmo_Ammo[weapon] > TurnaboutAmmo_Max[weapon])
		TurnaboutAmmo_Ammo[weapon] = TurnaboutAmmo_Max[weapon];
	
	SetAmmo_Weapon(client, weapon, TurnaboutAmmo_Ammo[weapon]);
	SetClip_Weapon(weapon, TurnaboutAmmo_Ammo[weapon]);
	
	LastTick[client] = GetEngineTime();
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	TurnaboutAmmo[ent] = false;
	TurnaboutAmmo_GainOnSap[ent] = 0;
	TurnaboutAmmo_GainOnBackstab[ent] = 0;
	TurnaboutAmmo_Ammo[ent] = 0;
}

public OnEntityCreated(entity, const String:cls[])
{
	if(entity < 0 || entity > 2048)
		return;
	
	if(!StrContains(cls, "obj_", false))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage_Building);
	}
}