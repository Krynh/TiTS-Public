package classes.Engine.Combat 
{
	import classes.Creature;
	import classes.Engine.Combat.DamageTypes.DamageResult;
	import classes.Engine.Combat.DamageTypes.TypeCollection;
	import classes.ItemSlotClass;
	import classes.Engine.Combat.DamageTypes.DamageType;
	import classes.Engine.Utility.rand;
	import classes.Characters.PlayerCharacter;
	import classes.Engine.Interfaces.output;
	import classes.Engine.Combat.DamageTypes.DamageFlag;
	import classes.kGAMECLASS;
	
	/**
	 * ...
	 * @author Gedan
	 */
	public function calculateDamage(baseDamage:TypeCollection, attacker:Creature, target:Creature, special:String = ""):DamageResult
	{
		// Split damage into the two components -- HP/Shield and Lust
		
		var baseHPDamage:TypeCollection = new TypeCollection();
		var baseLustDamage:TypeCollection = new TypeCollection();
		
		for (var i:uint = 0; i < DamageType.NUMTYPES; i++)
		{
			if (baseDamage.getType(i).isHPDamage) baseHPDamage.getType(i).damageValue = baseDamage.getType(i).damageValue;
			else baseLustDamage.getType(i).damageValue = baseDamage.getType(i).damageValue;
		}
		
		var dFlags:Vector.<DamageFlag> = baseDamage.getFlags();
		
		for (i = 0; i < dFlags.length; i++)
		{
			var df:DamageFlag = new DamageFlag();
			var dfl:DamageFlag = new DamageFlag();
			
			df.loadSaveObject(dFlags[i].getSaveObject());
			dfl.loadSaveObject(dFlags[i].getSaveObject());
			
			baseHPDamage.addDamageFlag(df);
			baseLustDamage.addDamageFlag(dfl);
		}
		
		var damageResult:DamageResult = new DamageResult();
		
		/****************************
		 * Apply damage bonuses here
		 ****************************/
		
		// Take care HOW you apply bonuses here -- lust AND hp damage can be modified
		// Special will allow you to apply bonus only to 'default' attacks.
		
		if (attacker != null && (special == "ranged" || special == "melee"))
		{
			var crittyBonus:Number = 0;
			if(attacker.hasPerk("Giant Slayer") && target.tallness >= 7*12) crittyBonus += 5;

			if(target.hasStatusEffect("Deep Freeze") && baseDamage.hasFlag(DamageFlag.CRUSHING))
			{
				damageResult.wasCrit = true;
				baseHPDamage.multiply(target.statusEffectv3("Deep Freeze"));
			}

			
			if (special == "melee")
			{				
				// Melee crit
				if(attacker.critBonus(true) + crittyBonus >= rand(100) + 1 && (attacker is PlayerCharacter || attacker.hasPerk("Can Crit")))
				{
					damageResult.wasCrit = true;
					baseHPDamage.multiply(2);
				}
				//Alpha strike forcing them criiiiiits!
				else if (attacker.hasPerk("Alpha Strike") && !attacker.hasStatusEffect("AlphaedStroked"))
				{
					damageResult.wasCrit = true;
					baseHPDamage.multiply(2);
				}
				
				// Sneak attack
				if ((target.hasStatusEffect("Stunned") || target.hasStatusEffect("Blinded")) && attacker.hasPerk("Sneak Attack")) 
				{
					damageResult.wasSneak = true;
					
					baseHPDamage.add(attacker.level * 3 + attacker.intelligence()/2);
					if (attacker.hasStatusEffect("Take Advantage")) baseHPDamage.add(attacker.level * 2);
					if	(target.hasStatusEffect("Stunned") && target.hasStatusEffect("Blinded")) baseHPDamage.add(attacker.level);
				}
				
				//Burninate the countryside
				if (baseHPDamage.getTotal() > 0 && baseHPDamage.hasFlag(DamageFlag.CHANCE_APPLY_BURN) && target.willTakeBurnDamage(baseDamage.burning.damageValue) && rand(5) == 0)
				{
					target.createStatusEffect("Burn",2,0,0,0,false,"Icon_Smelly","Burning for thermal damage over time.",true,0);
				}

				//Electrified weapons do more damage based on int!
				if (attacker.hasStatusEffect("Charged Weapon"))
				{
					var chargeBonus:Number = attacker.intelligence();
					if (attacker.hasPerk("Fuck Sense")) 
					{
						chargeBonus = attacker.libido();
						if(chargeBonus > attacker.level * 5) chargeBonus = attacker.level * 5;
					}
					baseHPDamage.add(new TypeCollection( { electric: chargeBonus } ));
				}

				//Special counter - added when PC melees something. Eaten at the end of the round.
				if(attacker is PlayerCharacter && !target.hasStatusEffect("Melee Counter")) target.createStatusEffect("Melee Counter",0,0,0,0);
			}
			else
			{
				if (attacker.hasStatusEffect("Concentrated Fire"))
				{
					baseHPDamage.add(attacker.statusEffectv1("Concentrated Fire"));
				}
				
				// Ranged crit 
				if(attacker.critBonus(false) + crittyBonus >= rand(100) + 1 && (attacker is PlayerCharacter || attacker.hasPerk("Can Crit")))
				{
					damageResult.wasCrit = true;
					baseHPDamage.multiply(2);
				}
				//Alpha strike forcing them criiiiiits!
				else if (attacker.hasPerk("Alpha Strike") && !attacker.hasStatusEffect("AlphaedStroked"))
				{
					damageResult.wasCrit = true;
					baseHPDamage.multiply(2);
				}
				
				// Sneak Attack (AKA Aimed Shot)
				if ((target.hasStatusEffect("Stunned") || target.hasStatusEffect("Blinded")) && attacker.hasPerk("Aimed Shot")) 
				{
					output("\n<b>Aimed shot!</b>");
					baseHPDamage.add(attacker.level * 3 + attacker.intelligence()/2);
					if(attacker.hasStatusEffect("Take Advantage")) baseHPDamage.add(attacker.level * 2);
					if(target.hasStatusEffect("Stunned") && target.hasStatusEffect("Blinded")) baseHPDamage.add(attacker.level);
				}
				
				//Burninate the countryside
				if (baseHPDamage.getTotal() > 0 && baseHPDamage.hasFlag(DamageFlag.CHANCE_APPLY_BURN) && target.willTakeBurnDamage(baseDamage.burning.damageValue) && rand(5) == 0)
				{
					target.createStatusEffect("Burn",2,0,0,0,false,"Icon_Smelly","Burning for thermal damage over time.",true,0);
				}
			}
			//Track Alpha Strike. Don't need to track the perk here cause who cares.
			if(!attacker.hasStatusEffect("AlphaedStroked") && damageResult.wasCrit == true) attacker.createStatusEffect("AlphaedStroked",0,0,0,0,true,"","",true);
		}
		
		

		/****************************
		 * Now apply the damage.
		 ****************************/		
		damageResult.remainingDamage = baseHPDamage;
		damageResult.remainingLustDamage = baseLustDamage;
		
		if (!damageResult.remainingDamage.hasFlag(DamageFlag.BYPASS_SHIELD) && damageResult.remainingDamage.getTotal() > 0)
		{
			calculateShieldDamage(target, attacker, damageResult, special);
			
			for (i = 0; i < DamageType.NUMTYPES; i++)
			{
				if (isNaN(damageResult.typedTotalDamage.getType(i).damageValue)) throw new Error("NaN");
			}
		}
		
		if (!damageResult.remainingDamage.hasFlag(DamageFlag.ONLY_SHIELD) && damageResult.remainingDamage.getTotal() > 0)
		{
			calculateHPDamage(target, attacker, damageResult, special);
			
			for (i = 0; i < DamageType.NUMTYPES; i++)
			{
				if (isNaN(damageResult.typedTotalDamage.getType(i).damageValue)) throw new Error("NaN");
			}
		}
		
		if (damageResult.remainingLustDamage.getTotal() > 0)
		{
			calculateLustDamage(target, attacker, damageResult, special);
		}
		
		// Round all the values for display
		damageResult.hpDamage = Math.round(damageResult.hpDamage);
		damageResult.shieldDamage = Math.round(damageResult.shieldDamage);
		damageResult.lustDamage = Math.round(damageResult.lustDamage);
		damageResult.totalDamage = Math.round(damageResult.totalDamage);

		return damageResult;
	}

}
