/*

Created by: Zethax
Document created on: January 31st, 2019
Last edit made on: January 31st, 2019
Current version: v1.0

Attributes in this pack:
	- "stacking speed on kill"
		1) Maximum amount of stacks that can be accumulated
		2) Movement speed bonus per stack
		3) Damage penalty per stack
		
		On kill and on assist the player gains stacks.
		For every stack, the player gains X% movement speed and X% damage penalty.
		The movement speed bonus does not apply while spun up or aiming.
		A haste icon appears above the player's head at 50% stacks or more.

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

#define PLUGIN_NAME "tf_custom_speed_on_kill"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds an attribute associated with accumulated speed boosting on kill."
#define PLUGIN_VERS "v1.0"

#define PARTICLE_SPEED "powerup_icon_haste"

public Plugin:my_info = {
  
	name        = PLUGIN_NAME,
	author      = PLUGIN_AUTH,
	description = PLUGIN_DESC,
	version     = PLUGIN_VERS,
	url         = ""
};

public OnPluginStart() {
 	
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("post_inventory_application", OnPostInventoryApplication);
 	
	for(new i = 1 ; i < MaxClients ; i++)
	{
		if(!IsValidClient(i))
			continue;
  
		OnClientPutInServer(i);
	}
}

public OnMapStart()
{
	PrecacheParticle(PARTICLE_SPEED);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_Think, OnClientThink);
}

new bool:StackSpeedOnKill[2049];
new Float:StackSpeedOnKill_MoveSpd[2049];
new Float:StackSpeedOnKill_Penalty[2049];
new StackSpeedOnKill_MaxStacks[2049];
new StackSpeedOnKill_Stacks[2049];
new StackSpeedOnKill_Particle[MAXPLAYERS + 1] = -1;

//Used to track changes in stacks to reapply attributes
new StackSpeedOnKill_PrevStacks[2049];

new Float:LastTick[MAXPLAYERS + 1];
new bool:SpunUp[MAXPLAYERS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return Plugin_Continue;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return Plugin_Continue;
	
	if(StrEqual(attrib, "stacking speed on kill"))
	{
		new String:values[3][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		StackSpeedOnKill_MaxStacks[weapon] = StringToInt(values[0]);
		StackSpeedOnKill_MoveSpd[weapon] = StringToFloat(values[1]);
		StackSpeedOnKill_Penalty[weapon] = StringToFloat(values[2]);
		
		StackSpeedOnKill[weapon] = true;
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new assister = GetClientOfUserId(GetEventInt(event, "assister"));
	
	if(attacker && Victim)
	{
		new weapon = GetActiveWeapon(attacker);
		if(StackSpeedOnKill[weapon])
		{
			StackSpeedOnKill_Stacks[weapon] += 2;
			if(StackSpeedOnKill_Stacks[weapon] > StackSpeedOnKill_MaxStacks[weapon])
				StackSpeedOnKill_Stacks[weapon] = StackSpeedOnKill_MaxStacks[weapon];
			
			//calculating bonuses and penalty
			new Float:speed = 1.0 + (StackSpeedOnKill_MoveSpd[weapon] * StackSpeedOnKill_Stacks[weapon]);
			new Float:penalty = 1.0 - (StackSpeedOnKill_Penalty[weapon] * StackSpeedOnKill_Stacks[weapon]);
			
			//applying said bonuses and penalties
			TF2Attrib_SetByName(weapon, "move speed bonus", speed);
			TF2Attrib_SetByName(weapon, "damage penalty", penalty);
			
			if(StackSpeedOnKill_Stacks[weapon] >= StackSpeedOnKill_MaxStacks[weapon] / 2 && 
				StackSpeedOnKill_Particle[attacker] == -1)
			{
				new Float:pos[3];
				pos[2] += 100.0;
				StackSpeedOnKill_Particle[attacker] = AttachParticle(attacker, PARTICLE_SPEED, -1.0, pos);
			}
			
			TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, 0.01);
		}
		if(StackSpeedOnKill_Particle[Victim] > -1)
		{
			CreateTimer(0.0, RemoveParticle, StackSpeedOnKill_Particle[Victim]);
			StackSpeedOnKill_Particle[Victim] = -1;
		}
	}
	if(assister && Victim)
	{
		new weapon = GetActiveWeapon(assister);
		if(StackSpeedOnKill[weapon])
		{
			StackSpeedOnKill_Stacks[weapon]++;
			if(StackSpeedOnKill_Stacks[weapon] > StackSpeedOnKill_MaxStacks[weapon])
				StackSpeedOnKill_Stacks[weapon] = StackSpeedOnKill_MaxStacks[weapon];
		}
	}
}

public Action:OnPostInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidClient(client))
	{
		if(StackSpeedOnKill_Particle[client] > -1)
		{
			CreateTimer(0.0, RemoveParticle, StackSpeedOnKill_Particle[client]);
			StackSpeedOnKill_Particle[client] = -1;
		}
	}
}

public OnClientThink(client)
{
	if(!IsValidClient(client))
		return;
	
	new weapon = GetPlayerWeaponSlot(client, 1);
	if(weapon < 0 || weapon > 2048)
		return;
	
	if(!StackSpeedOnKill[weapon])
		return;
	
	if(GetEngineTime() > LastTick[client] + 0.1)
		StackSpeedOnKill_Think(client, weapon);
}

static void StackSpeedOnKill_Think(client, weapon)
{
	if(TF2_IsPlayerInCondition(client, TFCond:0) && !SpunUp[client])
	{
		TF2Attrib_RemoveByName(weapon, "move speed bonus");
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
		
		if(StackSpeedOnKill_Particle[client] > -1)
		{
			CreateTimer(0.0, RemoveParticle, StackSpeedOnKill_Particle[client]);
			StackSpeedOnKill_Particle[client] = -1;
		}
		
		SpunUp[client] = true;
	}
	else if(!TF2_IsPlayerInCondition(client, TFCond:0) && SpunUp[client])
	{
		new Float:speed = 1.0 + (StackSpeedOnKill_MoveSpd[weapon] * StackSpeedOnKill_Stacks[weapon]);
		
		TF2Attrib_SetByName(weapon, "move speed bonus", speed);
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
		
		if(StackSpeedOnKill_Stacks[weapon] == StackSpeedOnKill_MaxStacks[weapon] / 2 && 
			StackSpeedOnKill_Particle[client] == -1)
		{
			new Float:pos[3];
			pos[2] += 100.0;
			StackSpeedOnKill_Particle[client] = AttachParticle(client, PARTICLE_SPEED, -1.0, pos);
		}
		SpunUp[client] = false;
	}
	
	LastTick[client] = GetEngineTime();
}

public OnEntityDestroyed(ent)
{
    if(ent < 0 || ent > 2048)
        return;
	
	StackSpeedOnKill[ent] = false;
	StackSpeedOnKill_MaxStacks[ent] = 0;
	StackSpeedOnKill_MoveSpd[ent] = 0.0;
	StackSpeedOnKill_Penalty[ent] = 0.0;
	StackSpeedOnKill_Stacks[ent] = 0;
	StackSpeedOnKill_PrevStacks[ent] = 0;
}
