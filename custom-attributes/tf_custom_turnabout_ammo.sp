/*

Created by: Zethax
Document created on: February 27th, 2019
Last edit made on: February 28th, 2019
Current version: v0.0

Attributes in this pack:
	- "turnabout ammo"
		1) Maximum amount of ammo the weapon is allowed to accumulate
		2) Amount of ammo gained on backstab
		3) Amount of ammo gained upon successfully sapping a building

*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <cw3-attributes>
#include <zethax>

#define PLUGIN_NAME "tf_custom_turnabout_ammo"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds an attribute that grants your primary weapon infinite ammo based on accuracy."
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
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}

new bool:TurnaboutAmmo[2049];
new TurnaboutAmmo_Max[2049];
new TurnaboutAmmo_GainOnSap[2049];
new TurnaboutAmmo_GainOnBackstab[2049];
new TurnaboutAmmo_Ammo[2049];

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
		new String:values[3][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		TurnaboutAmmo_Max[weapon] = StringToInt(values[0]);
		if(strlen(values[1]))
			TurnaboutAmmo_GainOnBackstab[weapon] = StringToInt(values[1]);
		if(strlen(values[2]))
			TurnaboutAmmo_GainOnSap[weapon] = StringToInt(values[2]);
		
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
	
	TurnaboutAmmo_Ammo[weapon]--;
	SetEntProp(weapon, Prop_Send, "m_iClip1", TurnaboutAmmo_Ammo[weapon]);
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
				
				SetEntProp(primary, Prop_Send, "m_iClip1", TurnaboutAmmo_Ammo[primary]);
			}
		}
		if(TurnaboutAmmo[weapon])
		{
			TurnaboutAmmo_Ammo[weapon]++;
			SetEntProp(weapon, Prop_Send, "m_iClip1", TurnaboutAmmo_Ammo[weapon]);
		}
	}
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
