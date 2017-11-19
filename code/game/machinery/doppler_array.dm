GLOBAL_LIST_EMPTY(doppler_arrays)

/obj/machinery/doppler_array
	name = "tachyon-doppler array"
	desc = "A highly precise directional sensor array which measures the release of quants from decaying tachyons. The doppler shifting of the mirror-image formed by these quants can reveal the size, location and temporal affects of energetic disturbances within a large radius ahead of the array.\n<span class='notice'>Alt-click to rotate it clockwise.</span>"
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "tdoppler"
	density = TRUE
	anchored = TRUE
	var/integrated = FALSE
	var/max_dist = 150
	verb_say = "states coldly"

/obj/machinery/doppler_array/Initialize()
	. = ..()
	GLOB.doppler_arrays += src

/obj/machinery/doppler_array/Destroy()
	GLOB.doppler_arrays -= src
	return ..()

/obj/machinery/doppler_array/process()
	return PROCESS_KILL

/obj/machinery/doppler_array/attackby(obj/item/O, mob/user, params)
	if(istype(O, /obj/item/wrench))
		if(!anchored && !isinspace())
			anchored = TRUE
			power_change()
			to_chat(user, "<span class='notice'>You fasten [src].</span>")
		else if(anchored)
			anchored = FALSE
			power_change()
			to_chat(user, "<span class='notice'>You unfasten [src].</span>")
		playsound(loc, O.usesound, 50, 1)
	else
		return ..()

/obj/machinery/doppler_array/verb/rotate()
	set name = "Rotate Tachyon-doppler Dish"
	set category = "Object"
	set src in oview(1)

	if(!usr || !isturf(usr.loc))
		return
	if(usr.stat || usr.restrained() || !usr.canmove)
		return
	src.setDir(turn(src.dir, 90))
	return

/obj/machinery/doppler_array/AltClick(mob/living/user)
	if(!istype(user) || user.incapacitated())
		to_chat(user, "<span class='warning'>You can't do that right now!</span>")
		return
	if(!in_range(src, user))
		return
	else
		rotate()

/obj/machinery/doppler_array/proc/sense_explosion(turf/epicenter,devastation_range,heavy_impact_range,light_impact_range,
												  took,orig_dev_range,orig_heavy_range,orig_light_range)
	if(stat & NOPOWER)
		return
	var/turf/zone = get_turf(src)

	if(zone.z != epicenter.z)
		return

	var/distance = get_dist(epicenter, zone)
	var/direct = get_dir(zone, epicenter)

	if(distance > max_dist)
		return
	if(!(direct & dir) && !integrated)
		return


	var/list/messages = list("Explosive disturbance detected.", \
							 "Epicenter at: grid ([epicenter.x],[epicenter.y]). Temporal displacement of tachyons: [took] seconds.", \
							 "Factual: Epicenter radius: [devastation_range]. Outer radius: [heavy_impact_range]. Shockwave radius: [light_impact_range].")

	// If the bomb was capped, say its theoretical size.
	if(devastation_range < orig_dev_range || heavy_impact_range < orig_heavy_range || light_impact_range < orig_light_range)
		messages += "Theoretical: Epicenter radius: [orig_dev_range]. Outer radius: [orig_heavy_range]. Shockwave radius: [orig_light_range]."

	if(integrated)
		var/obj/item/clothing/head/helmet/space/hardsuit/helm = loc
		if(!helm || !istype(helm, /obj/item/clothing/head/helmet/space/hardsuit))
			return
		helm.display_visor_message("Explosion detected! Epicenter: [devastation_range], Outer: [heavy_impact_range], Shock: [light_impact_range]")
	else
		for(var/message in messages)
			say(message)

/obj/machinery/doppler_array/power_change()
	if(stat & BROKEN)
		icon_state = "[initial(icon_state)]-broken"
	else
		if(powered() && anchored)
			icon_state = initial(icon_state)
			stat &= ~NOPOWER
		else
			icon_state = "[initial(icon_state)]-off"
			stat |= NOPOWER

//Portable version, built into EOD equipment. It simply provides an explosion's three damage levels.
/obj/machinery/doppler_array/integrated
	name = "integrated tachyon-doppler module"
	integrated = TRUE
	max_dist = 21 //Should detect most explosions in hearing range.
	use_power = NO_POWER_USE

/obj/machinery/doppler_array/research
	name = "tachyon-dopplar research array"
	desc = "A specialized tacyhon-dopplar bomb detection array that uses the results of the highest yield of explosions for research."
	var/datum/techweb/linked_techweb

/obj/machinery/doppler_array/research/sense_explosion(turf/epicenter, dev, heavy, light, time, orig_dev, orig_heavy, orig_light)	//probably needs a way to ignore admin explosives later on
	. = ..()
	if(!istype(linked_techweb))
		say("Warning: No linked research system!")
		return
	var/point_gain = techweb_scale_bomb(orig_light - 20 - linked_techweb.max_bomb_value)
	if(!point_gain)
		return
	linked_techweb.max_bomb_value = orig_light - 20
	linked_techweb.research_points += point_gain
	say("Gained [point_gain] points from explosion dataset.")

/obj/machinery/doppler_array/research/science

/obj/machinery/doppler_array/research/science/Initialize()
	. = ..()
	linked_techweb = SSresearch.science_tech

/proc/techweb_scale_bomb(lightradius)
	return (lightradius ** 0.5) * 13000
