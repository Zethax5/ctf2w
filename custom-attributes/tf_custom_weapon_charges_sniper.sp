/*

Created by: Zethax
Document created on: February 21st, 2019
Last edit made on: February 21st, 2019
Current version: v1.0

Attributes in this pack:
	- "weapon charges sniper rifle"
		1) Amount to gain on hit
		2) Amount to gain on kill
		3) Amount to lose upon firing sniper/bow
		
		On hit/kill gain X% minimum sniper charge/bow charge rate
		Upon firing your sniper/bow you lose X% of this charge

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

#define PLUGIN_NAME "tf_custom_weapon_charges_sniper"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds an attribute that charges your sniper rifle on kill"
#define PLUGIN_VERS "v1.0"

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
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}

new bool:KillsChargeSniper[2049];
new Float:KillsChargeSniper_OnHit[2049];
new Float:KillsChargeSniper_OnKill[2049];
new Float:KillsChargeSniper_Drain[2049];
new Float:MinimumSniperCharge[2049];
new Float:BowChargeRate[2049];
new Float:ChargeDrain[2049];
new bool:ChargingBow[2049];

//apparently this isn't just on kill
//gonna have to rename the attribute itself, not renaming the variables

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "weapon charges sniper rifle"))
	{
		new String:values[3][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		KillsChargeSniper_OnHit[weapon] = StringToFloat(values[0]);
		KillsChargeSniper_OnKill[weapon] = StringToFloat(values[1]);
		KillsChargeSniper_Drain[weapon] = StringToFloat(values[2]);
		
		//Initializes ammo counter
		SetEntProp(weapon, Prop_Send, "m_iClip1", 0);
		SetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType", 4);
		
		KillsChargeSniper[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (weapon == -1) return Plugin_Continue;
	if (MinimumSniperCharge[weapon] > 0.0 && GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") > 0.0)
	{
		MinimumSniperCharge[weapon] -= ChargeDrain[weapon];
		new melee = GetPlayerWeaponSlot(client, 2);
		SetEntProp(melee, Prop_Send, "m_iClip1", RoundFloat(MinimumSniperCharge[weapon]));
	}
	
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:ang[3], &weapon2)
{
	new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (weapon <= 0 || weapon > 2048) 
		return Plugin_Continue;
	
	if(MinimumSniperCharge[weapon] || BowChargeRate[weapon])
		KillsChargeSniper_OnRunCmd(client, buttons, weapon);
	
	return Plugin_Continue;
}

public OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype, weapon, const Float:damageForce[3], const Float:damagePosition[3], damageCustom)
{
	if(attacker)
	{
		if(weapon > -1 && KillsChargeSniper[weapon])
		{
			new primary = GetPlayerWeaponSlot(attacker, 0);
			if(IsValidEdict(primary))
				KillsChargeSniper_OnTakeDamage(primary, weapon);
		}
		LastWeaponHurtWith[attacker] = weapon;
	}
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new weapon = GetActiveWeapon(attacker);
	
	if(attacker)
	{
		if(KillsChargeSniper[weapon])
		{
			new primary = GetPlayerWeaponSlot(attacker, 0);
			if(IsValidEdict(primary))
				KillsChargeSniper_OnPlayerDeath(primary, weapon);
		}
	}
}

void KillsChargeSniper_OnRunCmd(client, buttons, weapon)
{
	new wep = GetPlayerWeaponSlot(client, 2);
	
	if (MinimumSniperCharge[weapon])
	{
		new Float:chargeLevel = GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage");
		if (chargeLevel > 0.0 && chargeLevel < MinimumSniperCharge[weapon])
			SetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage", MinimumSniperCharge[weapon]);
		if(MinimumSniperCharge[weapon] == 100.0)
			SetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage", MinimumSniperCharge[weapon] + 50.0);
		
		SetEntProp(wep, Prop_Send, "m_iClip1", RoundFloat(MinimumSniperCharge[weapon]));
	}
	
	if(BowChargeRate[weapon] && (buttons & IN_ATTACK) == IN_ATTACK)
	{
		ChargingBow[weapon] = true;
	}
	if(ChargingBow[weapon] && (buttons & IN_ATTACK) != IN_ATTACK)
	{
		BowChargeRate[weapon] -= ChargeDrain[weapon];
		TF2Attrib_SetByName(weapon, "fire rate penalty HIDDEN", 1.0 - BowChargeRate[weapon]);
		if (BowChargeRate[weapon] < 0.0)
			BowChargeRate[weapon] = 0.0;
			
		SetEntProp(wep, Prop_Send, "m_iClip1", RoundFloat(BowChargeRate[weapon] * 100.0));
		
		ChargingBow[weapon] = false;
	}
}

void KillsChargeSniper_OnTakeDamage(primary, weapon)
{
	new String:class[25];
	GetEdictClassname(primary, class, sizeof(class));
	if(!StrContains(class, "tf_weapon_sniperrifle", false))
	{
		MinimumSniperCharge[primary] += KillsChargeSniper_OnHit[weapon] * 100.0;
		if(MinimumSniperCharge[primary] > 100.0)
			MinimumSniperCharge[primary] = 100.0;
		ChargeDrain[primary] = KillsChargeSniper_Drain[weapon] * 100.0;
		
		SetEntProp(weapon, Prop_Send, "m_iClip1", RoundFloat(MinimumSniperCharge[primary]));
	}
	else if(!StrContains(class, "tf_weapon_compound_bow", false))
	{
		BowChargeRate[primary] += KillsChargeSniper_OnHit[weapon];
		if(BowChargeRate[primary] > 0.9)
			BowChargeRate[primary] = 0.9;
		
		ChargeDrain[primary] = KillsChargeSniper_Drain[weapon];
		//Bows use charge rate rather than minimum charge
		//So this must be applied to allow the bow to charge fast
		TF2Attrib_SetByName(primary, "fire rate penalty HIDDEN", 1.0 - BowChargeRate[primary]);
		
		SetEntProp(weapon, Prop_Send, "m_iClip1", RoundFloat(BowChargeRate[primary] * 100.0));
	}
}

void KillsChargeSniper_OnPlayerDeath(primary, weapon)
{
	new String:class[25];
	GetEdictClassname(primary, class, sizeof(class));
	if(!StrContains(class, "tf_weapon_sniperrifle", false))
	{
		MinimumSniperCharge[primary] += KillsChargeSniper_OnKill[weapon] * 100.0;
		if(MinimumSniperCharge[primary] > 100.0)
			MinimumSniperCharge[primary] = 100.0;
		ChargeDrain[primary] = KillsChargeSniper_Drain[weapon] * 100.0;
		
		SetEntProp(weapon, Prop_Send, "m_iClip1", RoundFloat(MinimumSniperCharge[primary]));
	}
	else if(!StrContains(class, "tf_weapon_compound_bow", false))
	{
		BowChargeRate[primary] += KillsChargeSniper_OnKill[weapon];
		if(BowChargeRate[primary] > 0.9)
			BowChargeRate[primary] = 0.9;
		
		ChargeDrain[primary] = KillsChargeSniper_Drain[weapon];
		//Bows use charge rate rather than minimum charge
		//So this must be applied to allow the bow to charge fast
		TF2Attrib_SetByName(primary, "fire rate penalty HIDDEN", 1.0 - BowChargeRate[primary]);
		
		SetEntProp(weapon, Prop_Send, "m_iClip1", RoundFloat(BowChargeRate[primary] * 100.0));
	}
}

public OnEntityDestroyed(ent)
{
    if(ent < 0 || ent > 2048)
        return;
	
	KillsChargeSniper[ent] = false;
	KillsChargeSniper_OnHit[ent] = 0.0;
	KillsChargeSniper_OnKill[ent] = 0.0;
	KillsChargeSniper_Drain[ent] = 0.0;
	MinimumSniperCharge[ent] = 0.0;
	BowChargeRate[ent] = 0.0;
	ChargeDrain[ent] = 0.0;
	ChargingBow[ent] = false;
}