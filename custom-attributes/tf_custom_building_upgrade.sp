/*
The previous version of this attribute was terribly made.
Using the ability associated with it was heavy on the server.
So, I'm remaking it.

Created by: Zethax
Document created on: January 16th, 2019
Last edit made on: January 17th, 2019
Current version: v0.0

Attributes in this pack:
	- "building upgrade attrib"
		1) Damage required to fully charge
		2) Sentry damage multiplier
		
		Dealing damage builds up a charge. When charged, use Special-attack to activate.
		Activating instantly heals and upgrades all your buildings. 

*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <cw3_attributes>
#include <zethax>

#define PLUGIN_NAME "tf_custom_building_ugrade"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds custom attributes associated with building upgrades"
#define PLUGIN_VERS "v0.0"

#define SOUND_UPGRADE "mvm/mvm_used_powerup.wav"

public Plugin:my_info = {
	
	name	    = PLUGIN_NAME,
	author	    = PLUGIN_AUTH,
	description = PLUGIN_DESC,
	version	    = PLUGIN_VERS,
	url	    = ""
};

public OnPluginStart() {
 
 for(new i = 1 ; i < MaxClients ; i++)
 {
	if(!IsValidClient(i))
	 continue;
	
	OnClientPutInServer(i);
 }
}

public OnMapStart()
{
	PrecacheSound(SOUND_UPGRADE, true);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	SDKHook(Client, SDKHook_PostThinkPost, OnClientPostThinkPost);
}

new bool:BuildingUpgrade[2049];
new Float:BuildingUpgrade_MaxCharge[2049];
new Float:BuildingUpgrade_SentryMult[2049];
new Float:BuildingUpgrade_Charge[2049];

//For keeping track of the owner of various buildings
new SentryOwner[MAXPLAYERS + 1];
new DispenserOwner[MAXPLAYERS + 1];
new TeleporterOwner1[MAXPLAYERS + 1];
new TeleporterOwner2[MAXPLAYERS + 1];

new Float:LastTick[MAXPLAYERS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(attrib, "tf_custom_building_upgrade"))
		return;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return;
	
	if(StrEqual(attrib, "building upgrade attrib"))
	{
		new String:values[2][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		BuildingUpgrade_MaxCharge[weapon] = StringToFloat(values[0]);
		BuildingUpgrade_SentryMult[weapon] = StringToFloat(values[1]);
		
		//Initializes ammo counter
		SetEntProp(weapon, Prop_Send, "m_iClip1", 0);
		SetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType", 4);
		
		BuildingUpgrade[weapon] = true;
		action = Plugin_Handled;
	}
	return action;
}

public OnTakeDamageAlive(victim, attacker, inflictor, Float:damage, damagetype, weapon, const Float:damageForce[3], const Float:damagePosition[3])
{
	if(attacker && victim)
	{
		if(BuildingUpgrade[GetPlayerWeaponSlot(attacker, 2)])
		{
			new melee = GetPlayerWeaponSlot(attacker, 2);
			
			if(inflictor == SentryOwner[attacker])
				BuildingUpgrade_Charge[melee] += damage * BuildingUpgrade_SentryMult[melee];
			else
				BuildingUpgrade_Charge[melee] += damage;
			
			if(BuildingUpgrade_Charge[melee] > BuildingUpgrade_MaxCharge[melee])
				BuildingUpgrade_Charge[melee] = BuildingUpgrade_MaxCharge[melee];
		}
	}
}

public OnClientPostThinkPost(client)
{
	if(!IsValidClient(client))
		return;
	
	new weapon = GetActiveWeapon(client);
	if(weapon < 0 || weapon > 2048)
		return;
	
	if(!BuildingUpgrade[weapon])
		return;
	
	if(GetEngineTime() > LastTick[client] + 0.1)
		BuildingUpgrade_PostThink(client, weapon);
}

static void BuildingUpgrade_PostThink(client, weapon)
{	
	new buttons = GetClientButtons(client);
	if(BuildingUpgrade_Charge[weapon] == BuildingUpgrade_MaxCharge[weapon])
	{
		if((buttons & IN_ATTACK3) == IN_ATTACK3)
		{
			BuildingUpgrade_Charge[weapon] = 0.0;
			
			BuildingUpgrade_ApplyUpgrade(SentryOwner[client], client);
			BuildingUpgrade_ApplyUpgrade(DispenserOwner[client], client);
			BuildingUpgrade_ApplyUpgrade(TeleporterOwner1[client], client);
			BuildingUpgrade_ApplyUpgrade(TeleporterOwner2[client], client);
			
			EmitSoundToClient(client, SOUND_UPGRADE);
		}
	}
	
	//Displays charge with ammo meter
	SetEntProp(weapon, Prop_Send, "m_iClip1", RoundFloat(BuildingUpgrade_Charge[weapon] / BuildingUpgrade_MaxCharge[weapon]) * 100.0);
	
	LastTick[client] = GetEngineTime();
}

static void BuildingUpgrade_ApplyUpgrade(ent, client)
{
	new upgradelvl;
	new health;
	new maxhealth;
	if(ent > 0)
	{
		upgradelvl = GetEntProp(ent, Prop_Send, "m_iHighestUpgradeLevel")
		maxhealth = GetEntProp(ent, Prop_Data, "m_iMaxHealth");
		health = GetEntProp(ent, Prop_Data, "m_iHealth");
		
		if(upgradelvl < 3)
			PrintToChat(client, "Your TELEPORTER was upgraded");
		if(upgradelvl == 3 && health < maxhealth)
			PrintToChat(client, "Your TELEPORTER was healed");
				
		SetEntProp(ent, Prop_Send, "m_iHighestUpgradeLevel", 3);
		SetEntityHealth(ent, GetEntProp(TeleporterOwner2[client], Prop_Data, "m_iMaxHealth"));
	}
}

public OnEntityCreated(ent, const String:classname[])
{
	if(ent < 0 || ent > 2048)
		return;
		
	new owner = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	if(!IsValidClient(owner))
		return;
	
	if(StrContains(classname, "obj_sentrygun"))
		SentryOwner[owner] = ent;
	if(StrContains(classname, "obj_dispenser))
		DispenserOwner[owner] = ent;
	if(StrContains(classname, "obj_teleporter"))
	{
		if(TeleporterOwner1[owner] == 0)
			TeleporterOwner1[owner] = ent;
		else if(TeleporterOwner2[owner] == 0)
			TeleporterOwner2[owner] = ent;
	}
}

public OnEntityDestroyed(ent, const String:classname[])
{
	if(ent < 0 || ent > 2048)
		return;
		
	BuildingUpgrade[ent] = false;
	BuildingUpgrade_Charge[ent] = 0.0;
	BuildingUpgrade_MaxCharge[ent] = 0.0;
	BuildingUpgrade_SentryMult[ent] = 0.0;
	
	if(StrContains(classname, "obj_teleporter"))
	{
		new owner = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		if(!IsValidClient(owner))
			return;
		
		if(TeleporterOwner1[owner] == ent)
			TeleporterOwner1[owner] = 0;
			
		if(TeleporterOwner2[owner] == ent)
			TeleporterOwner2[owner] = 0;
	}
}
