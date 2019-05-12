/*

Created by: Zethax
Document created on: March 28th, 2019
Last edit made on: March 28th, 2019
Current version: v1.0

Attributes in this pack:
	-> "ubercharge is revive"
		1) Ubercharge drain on automatic use
		2) Ubercharge drain on manual use
		3) Max health to restore to patient on ubercharge
		4) Max health to restore to medic on ubercharge
		5) Max health to restore to medic on MANUAL ubercharge
		6) Patient health threshold for automatic ubercharge to trigger
		
		If Medic has enough Ubercharge, and the patient's health goes below the given threshold,
		the medigun will automatically trigger an Ubercharge. This restores a given amount of health
		to the patient and the Medic should he be wounded, and drains the Medic's Ubercharge.
		Automatic Ubercharges can save the patient from fatal damage.
		Manual Ubercharges can be triggered via alt-fire, granting instant health restoration to the
		Medic and the patient.

*/

#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <cw3-attributes>
#include <zethax>

#define PLUGIN_NAME "tf_custom_resurrection_uber"
#define PLUGIN_AUTH "Zethax"
#define PLUGIN_DESC "Adds an attribute which replaces ubercharge with a life-saver"
#define PLUGIN_VERS "v1.0"

#define SOUND_REVIVE "mvm/mvm_revive.wav"

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

public OnMapStart()
{
	PrecacheSound(SOUND_REVIVE, true);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_PreThink, OnClientPreThink);
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

new bool:ReviveUber[2049];
new Float:ReviveUber_ManualDrain[2049];
new Float:ReviveUber_AutoDrain[2049];
new Float:ReviveUber_PatientHealthRestore[2049];
new Float:ReviveUber_MedicHealthRestore[2049];
new Float:ReviveUber_MedicHealthRestoreManual[2049];
new Float:ReviveUber_Threshold[2049];
new Float:ReviveUber_UseDelay[2049];
new bool:PatientBackstabbed[MAXPLAYERS + 1];

new Float:LastTick[MAXPLAYERS + 1];
new LastPatient[MAXPLAYERS + 1];
new Healer[MAXPLAYERS + 1];

public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	new Action:action;
	if(!StrEqual(plugin, PLUGIN_NAME))
  		return action;
	
	new weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon < 0 || weapon > 2048)
		return action;
	
	if(StrEqual(attrib, "ubercharge is revive"))
	{
		new String:values[6][10];
		ExplodeString(value, " ", values, sizeof(values), sizeof(values[]));
		
		ReviveUber_AutoDrain[weapon] = StringToFloat(values[0]);
		ReviveUber_ManualDrain[weapon] = StringToFloat(values[1]);
		ReviveUber_PatientHealthRestore[weapon] = StringToFloat(values[2]);
		ReviveUber_MedicHealthRestore[weapon] = StringToFloat(values[3]);
		ReviveUber_MedicHealthRestoreManual[weapon] = StringToFloat(values[4]);
		ReviveUber_Threshold[weapon] = StringToFloat(values[5]);
		
		ReviveUber[weapon] = true;
		action = Plugin_Handled;
	}
	
	return action;
}

public OnClientPreThink(client)
{
	if(!IsValidClient(client))
		return;
	
	new weapon = GetActiveWeapon(client);
	if(weapon < 0 || weapon > 2048)
		return;
	
	if(!ReviveUber[weapon])
		return;
	
	if(GetEngineTime() >= LastTick[client] + 0.1)
	{
		ReviveUber_PreThink(client, weapon);
		
		LastTick[client] = GetEngineTime();
	}
	if(GetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel") > 0.99) 
		SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", 0.99);
}

public Action:OnTakeDamageAlive(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damageCustom)
{
	if(attacker && victim)
	{
		if(Healer[victim] > 0)
		{
			new healer = Healer[victim];
			new medigun = GetActiveWeapon(healer);
			if(medigun > -1 && ReviveUber[medigun])
			{
				new Float:ubercharge = GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel");
				new Float:mult = 1.0;
				if(damageCustom == TF_CUSTOM_BACKSTAB)
					mult = 2.0;
				
				if(ubercharge >= ReviveUber_AutoDrain[medigun] * mult)
				{
					new health = GetClientHealth(victim);
					if(damage >= health)
					{
						damage = float(health) - 2.0;
						ReviveUber_PreThink(healer, medigun);
						
						if(damageCustom == TF_CUSTOM_BACKSTAB)
							PatientBackstabbed[victim] = true;
						
						return Plugin_Changed;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

void ReviveUber_PreThink(client, weapon)
{
	new patient = GetMediGunPatient(client);
	new buttons = GetClientButtons(client);
	new Float:ubercharge = GetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel");
	if(patient > -1)
	{
		new Float:mult = 1.0;
		if(PatientBackstabbed[patient])
			mult = 2.0;
		if(ubercharge >= ReviveUber_AutoDrain[weapon] * mult)
		{
			new maxMedicHealth = GetClientMaxHealth(client);
			new maxPatientHealth = GetClientMaxHealth(patient);
			new medicHealth = GetClientHealth(client);
			new patientHealth = GetClientHealth(patient);
			new threshold = RoundFloat(maxPatientHealth * ReviveUber_Threshold[weapon]);
			if(patientHealth < threshold)
			{
				new healing = RoundFloat(maxPatientHealth * ReviveUber_PatientHealthRestore[weapon]);
				SetEntityHealth(patient, patientHealth + healing);
				
				healing = RoundFloat(maxMedicHealth * ReviveUber_MedicHealthRestore[weapon]);
				if(medicHealth + healing > maxMedicHealth)
					healing = maxMedicHealth - medicHealth;
				
				SetEntityHealth(client, medicHealth + healing);
				
				EmitSoundToAll(SOUND_REVIVE, patient);
				
				SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", ubercharge - ReviveUber_AutoDrain[weapon] * mult);
				PatientBackstabbed[patient] = false;
			}
		}
		Healer[patient] = client;
		LastPatient[client] = patient;
	}
	else if(!IsValidClient(patient) && IsValidClient(LastPatient[client]))
	{
		Healer[LastPatient[client]] = -1;
		LastPatient[client] = -1;
	}
	
	if((buttons & IN_ATTACK2) == IN_ATTACK2 && GetEngineTime() >= ReviveUber_UseDelay[weapon] + 1.0)
	{
		new medicHealth = GetClientHealth(client);
		new maxMedicHealth = GetClientMaxHealth(client);
		if(ubercharge >= ReviveUber_ManualDrain[weapon])
		{
			new bool:ActionDone = false;
			if(medicHealth < maxMedicHealth)
			{
				new healing = RoundFloat(maxMedicHealth * ReviveUber_MedicHealthRestoreManual[weapon]);
				if(medicHealth + healing > maxMedicHealth)
					healing = maxMedicHealth - medicHealth;
				
				SetEntityHealth(client, medicHealth + healing);
				TF2_AddCondition(client, TFCond:70, 5.0);
				
				EmitSoundToAll(SOUND_REVIVE, client);
				
				ReviveUber_UseDelay[weapon] = GetEngineTime();
				ActionDone = true;
			}
			if(patient > -1)
			{
				new patientHealth = GetClientHealth(client);
				new maxPatientHealth = GetClientMaxHealth(client);
				if(patientHealth < maxPatientHealth)
				{
					new healing = RoundFloat(maxPatientHealth * ReviveUber_PatientHealthRestore[weapon]);
					if(patientHealth + healing < maxPatientHealth)
						healing = maxPatientHealth - patientHealth;
					
					SetEntityHealth(patient, patientHealth + healing);
					
					EmitSoundToAll(SOUND_REVIVE, patient);
					
					ReviveUber_UseDelay[weapon] = GetEngineTime();
					ActionDone = true;
				}
			}
			if(ActionDone)
				SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", ubercharge - ReviveUber_ManualDrain[weapon]);
		}
	}
}

public OnEntityDestroyed(ent)
{
	if(ent < 0 || ent > 2048)
		return;
	
	ReviveUber[ent] = false;
	ReviveUber_ManualDrain[ent] = 0.0;
	ReviveUber_AutoDrain[ent] = 0.0;
	ReviveUber_PatientHealthRestore[ent] = 0.0;
	ReviveUber_MedicHealthRestore[ent] = 0.0;
	ReviveUber_MedicHealthRestoreManual[ent] = 0.0;
	ReviveUber_Threshold[ent] = 0.0;
}
