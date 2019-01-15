/*

Created by: Zethax
Document created on: Wednesday, December 19th, 2018
Last edit made on: Sunday, January 14th, 2018
Current version: v1.0

Attributes in this plugin:
  - "shield on kill"
  	1) Resistance granted by shield
	2) Maximum damage shield can take in one hit
	
	Grants the user a shield on kill.
	While this shield is active, the user takes X% less damage.
	The shield will last until the user takes X damage or more from a single attack.
	
  - "shield explodes when destroyed"
  	Requires "shield on kill" to be on weapon of choice
	1) Radius of the explosion
	2) Maximum damage the explosion can deal
	3) Maximum falloff the explosion damage can experience
	
	When the shield granted by "shield on kill" is destroyed, this attribute triggers.
	This causes an explosion around the player, dealing damage to enemies within the specified radius

*/

#pragma semicolon 1
#include <sourcemod>
#include <cw3-attributes>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>
//#include <smlib>
#include <zethax>

#define PLUGIN_AUTHOR           "Zethax"
#define PLUGIN_DESC             "Yet another pack of attributes I've made for Crafting and his servers"
#define PLUGIN_VERSION          "v1.0"
#define PLUGIN_NAME             "Shield On Kill"

#define PARTICLE_SHIELD					"powerup_supernova_ready"
#define PARTICLE_EXPLODE        "ExplosionCore_Wall"

#define SOUND_EXPLODE 					"weapons/explode1.wav"
#define SOUND_SHIELD					"items/powerup_pickup_supernova.wav"

public Plugin:my_info = {
  
  name          = PLUGIN_NAME,
  author        = PLUGIN_AUTHOR,
  description   = PLUGIN_DESC,
  version       = PLUGIN_VERSION,
  url           = ""
};

public OnPluginStart() {
  	
	HookEvent("player_death", OnPlayerDeath);
  	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i)) 
      			continue;
		
		OnClientPutInServer(i);
	}
  
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

public OnMapStart() {
  
	PrecacheSound(SOUND_EXPLODE, true);
	PrecacheSound(SOUND_SHIELD, true);
	PrecacheParticle(PARTICLE_SHIELD);
	PrecacheParticle(PARTICLE_EXPLODE);
}

new bool:ShieldOnKill[2049];
new Float:ShieldOnKill_Resist[2049];
new Float:ShieldOnKill_MaxDmg[2049];
new ShieldOnKill_Particle[MAXPLAYERS + 1];

new bool:ShieldExplodes[2049];
new Float:ShieldExplodes_Radius[2049];
new Float:ShieldExplodes_MaxDmg[2049];
new Float:ShieldExplodes_Falloff[2049];

//Controls addition of attributes from this plugin
public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
  
	if(!StrEqual(plugin, "tf_custom_shield_on_kill"))
		return Plugin_Continue;
  
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon > 2048 || weapon < 0)
		return Plugin_Continue;

	if(StrEqual(attrib, "shield on kill"))
	{
		//PrintToChat(client, "applying shield on kill");
		new String:values[2][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
    
		ShieldOnKill_Resist[weapon] = StringToFloat(values[0]);
		ShieldOnKill_MaxDmg[weapon] = StringToFloat(values[1]);
		
		ShieldOnKill[weapon] = true;
		ShieldOnKill[client] = false;
		action = Plugin_Handled;
	}
	else if(StrEqual(attrib, "shield explodes when destroyed") && ShieldOnKill[weapon])
	{
		//PrintToChat(client, "applying explosive shield");
		new String:values[3][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
    
		ShieldExplodes_Radius[weapon]  = StringToFloat(values[0]);
		ShieldExplodes_MaxDmg[weapon]  = StringToFloat(values[1]);
		ShieldExplodes_Falloff[weapon] = StringToFloat(values[2]);
    		
		ShieldExplodes[weapon] = true;
		action = Plugin_Handled;
	}
  
	return action; 
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new vict = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new weapon = LastWeaponHurtWith[attacker];
	
	//PrintToChat(attacker, "A DEATH HAS BEEN DETECTED");
	
	if(attacker && vict)
	{
		if(ShieldOnKill[weapon] && !ShieldOnKill[attacker])
		{
			//PrintToChat(attacker, "Initializing shield");
			ShieldOnKill[attacker]           = true;
			ShieldOnKill_Resist[attacker]    = ShieldOnKill_Resist[weapon];
			ShieldOnKill_MaxDmg[attacker]    = ShieldOnKill_MaxDmg[weapon];
			ShieldOnKill_Particle[attacker]  = AttachParticle(attacker, PARTICLE_SHIELD, -1.0);
			EmitSoundToClient(attacker, SOUND_SHIELD);
			
			if(ShieldExplodes[weapon])
			{
				//PrintToChat(attacker, "initializing explosive shield");
				ShieldExplodes[attacker]          = true;
				ShieldExplodes_Radius[attacker]   = ShieldExplodes_Radius[weapon];
				ShieldExplodes_MaxDmg[attacker]   = ShieldExplodes_MaxDmg[weapon];
				ShieldExplodes_Falloff[attacker]  = ShieldExplodes_Falloff[weapon];
			}
			//PrintToChat(attacker, "Shield set");
		}
		if(ShieldOnKill[vict])
		{
			//PrintToChat(victim, "destroying shield");
			CreateTimer(0.0, RemoveParticle, ShieldOnKill_Particle[vict]);
			ShieldOnKill[vict]          = false;
			ShieldOnKill_Resist[vict]   = 0.0;
			ShieldOnKill_MaxDmg[vict]   = 0.0;
			ShieldOnKill_Particle[vict] = 0;
			
			if(ShieldExplodes[vict])
			{
				//PrintToChat(victim, "detonating shield");
				CreateTimer(0.0, RemoveParticle, ShieldOnKill_Particle[vict]);
				ShieldOnKill[vict]          = false;
				ShieldOnKill_Resist[vict]   = 0.0;
				ShieldOnKill_MaxDmg[vict]   = 0.0;
				ShieldOnKill_Particle[vict] = 0;
         
				if(ShieldExplodes[vict])
				{
					//PrintToChat(victim, "detonating shield");
					for(new i = 1; i < MaxClients; i++)
					{
						new Float:Pos1[3];
						GetClientAbsOrigin(vict, Pos1);
						if(IsValidClient(i) && GetClientTeam(i) != GetClientTeam(vict))
						{
							new Float:Pos2[3];
							GetClientAbsOrigin(i, Pos2);
							
							new Float:distance = GetVectorDistance(Pos1, Pos2);
               
							if(distance < ShieldExplodes_Radius[vict])
							{
								new ExplosionDamage = RoundToFloor(ShieldExplodes_MaxDmg[vict] * (1.0 - ((distance / ShieldExplodes_Radius[vict]) * ShieldExplodes_Falloff[vict])));
								DealDamage(i, ExplosionDamage, vict, _, "shield explosion");
							}
						}
					}
					
					SpawnParticle(vict, _, PARTICLE_EXPLODE);
					EmitSoundToAll(SOUND_EXPLODE, vict);
					
					ShieldExplodes[vict]         = false;
					ShieldExplodes_Radius[vict]  = 0.0;
					ShieldExplodes_MaxDmg[vict]  = 0.0;
					ShieldExplodes_Falloff[vict] = 0.0;
				}
			}//PrintToChat(victim, "shield destroyed");
		}
	}
	return Plugin_Continue;
}


public Action:OnTakeDamageAlive(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	new Action:action;
	if(attacker && victim)
	{
		if(weapon > 0 && weapon < 2049)
		{
			if(ShieldOnKill[victim])
			{
				//PrintToChat(victim, "damage resisted");
				damage *= 1.0 - ShieldOnKill_Resist[victim];
				action = Plugin_Changed;
        			
				if(damage > ShieldOnKill_MaxDmg[victim])
				{
					//PrintToChat(victim, "destroying shield");
					CreateTimer(0.0, RemoveParticle, ShieldOnKill_Particle[victim]);
					ShieldOnKill[victim]          = false;
					ShieldOnKill_Resist[victim]   = 0.0;
					ShieldOnKill_MaxDmg[victim]   = 0.0;
					ShieldOnKill_Particle[victim] = 0;
          
					if(ShieldExplodes[victim])
					{
						//PrintToChat(victim, "detonating shield");
						for(new i = 1; i < MaxClients; i++)
						{
							new Float:Pos1[3];
							GetClientAbsOrigin(victim, Pos1);
							if(IsValidClient(i) && GetClientTeam(i) != GetClientTeam(victim))
							{
								new Float:Pos2[3];
								GetClientAbsOrigin(i, Pos2);
								
								new Float:distance = GetVectorDistance(Pos1, Pos2);
                
								if(distance < ShieldExplodes_Radius[victim])
								{
									new ExplosionDamage = RoundToFloor(ShieldExplodes_MaxDmg[victim] * (1.0 - ((distance / ShieldExplodes_Radius[victim]) * ShieldExplodes_Falloff[victim])));
									DealDamage(i, ExplosionDamage, victim, _, "shield explosion");
								}
							}
						}
						
						SpawnParticle(victim, _, PARTICLE_EXPLODE);
						EmitSoundToAll(SOUND_EXPLODE, victim);
						
						ShieldExplodes[victim]         = false;
						ShieldExplodes_Radius[victim]  = 0.0;
						ShieldExplodes_MaxDmg[victim]  = 0.0;
						ShieldExplodes_Falloff[victim] = 0.0;
					}
					//PrintToChat(victim, "shield destroyed");
				}
			}
			LastWeaponHurtWith[attacker] = weapon;
		}
	}
	
	return action;
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2049) return;
	
	ShieldOnKill[ent] = false;
	ShieldOnKill_Resist[ent] = 0.0;
	ShieldOnKill_MaxDmg[ent] = 0.0;
	
	ShieldExplodes[ent] = false;
	ShieldExplodes_Radius[ent] = 0.0;
	ShieldExplodes_MaxDmg[ent] = 0.0;
	ShieldExplodes_Falloff[ent] = 0.0;
}


//Miscellaneous stuff

//Removes particles when called
public Action:RemoveParticle(Handle:timer, any:particle) //Chawlz' code
{
	if(particle >= 0 && IsValidEntity(particle))
	{
		new String:classname[32];
		GetEdictClassname(particle, classname, sizeof(classname));
		if(StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "Stop");
			AcceptEntityInput(particle, "Kill");
			AcceptEntityInput(particle, "Deactivate");
			particle = -1;
		}
	}
}
