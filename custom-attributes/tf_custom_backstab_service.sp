/*
Plugin description specificity: 100

Created by: Zethax
Document created on: January 31st, 2019
Last edit made on: January 31st, 2019
Current version: v1.0

Attributes in this pack:
	- "backstab service"
		1) Max stacks Spy can accumulate
		2) Move speed bonus per stack
		3) Cloak speed bonus per stack
		4) Decloak speed bonus per stack
		5) Blink time penalty per stack
		
		On backstab, Spy gains 1 stack. Per stack, he gains +X movement speed, +X cloak speed, +X decloak speed,
		and +X cloak blink time. This can stack up to X times. 

*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <cw3_attributes>
#include <zethax>

#define PLUGIN_NAME "tf_custom_backstab_service"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds attributes that buff the Spy based on backstabs."
#define PLUGIN_VERS "v1.0"

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

new bool:BackstabService[2049];
new Float:BackstabService_MoveSpd[2049];
new Float:BackstabService_CloakSpd[2049];
new Float:BackstabService_DecloakSpd[2049];
new Float:BackstabService_Debuff[2049];
new BackstabService_MaxStacks[2049];
new BackstabService_Stacks[2049];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return;
		
	if(StrEqual(attrib, "backstab service"))
	{
		new String:values[5][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		BackstabService_MaxStacks[weapon] = StringToFloat(values[0]);
		BackstabService_MoveSpd[weapon] = StringToFloat(values[1]);
		BackstabService_CloakSpd[weapon] = StringToFloat(values[2]);
		BackstabService_DecloakSpd[weapon] = StringToFloat(values[3]);
		BackstabService_Debuff[weapon] = StringToFloat(values[4]);
		
		//Initializes ammo counter
		SetEntProp(weapon, Prop_Send, "m_iClip1", 0);
		SetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType", 4);
		
		BackstabService[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public Action:OnTakeDamagePost(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damageCustom)
{
	if(attacker && victim)
	{
		if(BackstabService[weapon] && damageCustom == TF_CUSTOM_BACKSTAB)
		{
			BackstabService_Stacks[weapon]++;
			if(BackstabService_Stacks[weapon] > BackstabService_MaxStacks[weapon])
				BackstabService_Stacks[weapon] = BackstabService_MaxStacks[weapon];
			
			//Sets ammo display to show stacks
			SetEntProp(weapon, Prop_Send, "m_iClip1", BackstabService_Stacks[weapon]);
			
			TF2Attrib_SetByName(weapon, "move speed bonus", 1.0 + (BackstabService_MoveSpd[weapon] * BackstabService_Stacks[weapon]));
			TF2Attrib_SetByName(weapon, "mult cloak rate", 0.0 - (BackstabService_CloakSpd[weapon] * BackstabService_Stacks[weapon]));
			TF2Attrib_SetByName(weapon, "mult decloak rate", 1.0 - (BackstabService_DecloakSpd[weapon] * BackstabService_Stacks[weapon]));
			TF2Attrib_SetByName(weapon, "SET BONUS: cloak blink time penalty", 1.0 + (BackstabService_Debuff[weapon] * BackstabService_Stacks[weapon])
			TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, 0.001); //Updates player's movement speed
		}
	}
	return Plugin_Continue;
}

public OnEntityDestroyed(ent)
{
    if(ent < 0 || ent > 2048)
        return;
	
	BackstabService[weapon] = false;
	BackstabService_MoveSpd[weapon] = 0.0;
	BackstabService_CloakSpd[weapon] = 0.0;
	BackstabService_DecloakSpd[weapon] = 0.0;
	BackstabService_Debuff[weapon] = 0.0;
	BackstabService_MaxStacks[weapon] = 0;
	BackstabService_Stacks[weapon] = 0;
}

