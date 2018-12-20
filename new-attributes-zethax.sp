/*

Created by: Zethax
Document created on: Wednesday, December 19th, 2018
Last edit made on: Thursday, December 20th, 2018
Current version: v0.1

Attributes in this plugin:
  None so far

*/

#pragma semicolon 1
#include <sourcemod>
#include <cw3-attributes>
#include <tf2>
#include <zethax>

#define PLUGIN_AUTHOR           "Zethax"
#define PLUGIN_DESC             "Yet another pack of attributes I've made for Crafting and his servers"
#define PLUGIN_VERSION          "v0.1"
#define PLUGIN_NAME             "New Attributes"

#define PARTICLE_SHIELD					"powerup_supernova_ready"
#define PARTICLE_EXPLODE        "ExplosionCore_Wall"

#define SOUND_EXPLODE 					"weapons/explode1.wav"

public Plugin:my_info = {
  
  name          = PLUGIN_NAME,
  author        = PLUGIN_AUTHOR,
  description   = PLUGIN_DESCRIPTION,
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
  PrecacheParticle(PARTICLE_SHIELD);
  
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
  
  if(!StrEqual(plugin, "new-attributes-zethax"))
    return Plugin_Continue;
  
  new weapon = GetPlayerWeaponSlot(client, slot);
  if(weapon > 2048 || weapon < 0)
    return Plugin_Continue;
  
  if(StrEqual(attrib, "shield on kill"))
  {
    new String:values[2][10];
    ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
    
    ShieldOnKill_Resist[weapon] = StringToFloat(values[0]);
    ShieldOnKill_MaxDmg[weapon] = StringToFloat(values[1]);
    
    ShieldOnKill[weapon] = true;
    action = Plugin_Handled;
  }
  else if(StrEqual(attrib, "shield explodes when destroyed"))
  {
    new String:values[3][10];
    ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
    
    ShieldExplodes_Radius[weapon]  = StringToFloat(values[0]);
    ShieldExplodes_MaxDmg[weapon]  = StringToFloat(values[1]);
    ShieldExplodes_Falloff[weapon] = StringToFloat(Values[2]);
    
    ShieldExplodes[weapon] = true;
    action = Plugin_Handled;
  }
  
  return action; 
}

public void OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
  new victim = GetClientOfUserId(GetEventInt(event, "userid"));
  new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
  new weapon = GetEventInt(event, "weaponid");
  
  if(attacker && victim)
  {
    if(weapon > 0 || weapon < 2049)
    {
      if(ShieldOnKill[weapon] && !ShieldOnKill[attacker])
      {
         ShieldOnKill[attacker]           = true;
         ShieldOnKill_Resist[attacker]    = ShieldOnKill_Resist[weapon];
         ShieldOnKill_MaxDmg[attacker]    = ShieldOnKill_MaxDmg[weapon];
         ShieldOnKill_Particle[attacker]  = AttachParticle(attacker, PARTICLE_SHIELD, -1.0);
         
         if(ShieldExplodes[weapon])
         {
          ShieldExplodes[attacker]          = true;
          ShieldExplodes_Radius[attacker]   = ShieldExplodes_Radius[weapon];
          ShieldExplodes_MaxDmg[attacker]   = ShieldExplodes_MaxDmg[weapon];
          ShieldExplodes_Falloff[attacker]  = ShieldExplodes_Falloff[weapon];
         }
      }
      if(ShieldOnKill[victim])
      {
        
      }
    }
  }
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
        damage *= 1.0 - ShieldOnKill_Resist[victim];
        
        if(damage > ShieldOnKill_MaxDmg[victim])
        {
          CreateTimer(0.0, RemoveParticle, ShieldOnKill_Particle[victim]);
          ShieldOnKill[victim]          = false;
          ShieldOnKill_Resist[victim]   = 0.0;
          ShieldOnKill_MaxDmg[victim]   = 0.0;
          ShieldOnKill_Particle[victim] = 0;
          
          if(ShieldExplodes[victim])
          {
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
                  DealDamage(i, ShieldExplodes_MaxDmg[victim], victim, _, "shield explosion");
                }
              }
            }
          }
        }
      }
    }
  }
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
