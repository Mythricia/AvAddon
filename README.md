# AvAddon

AvAddon is a prototypical version of a World of Warcraft Addon for collecting a wide set of data during leveling, for later use in other Addons.

AvAddon consists mainly of a component called DataHoarder, which is responsible for collecting the data into a database, called (very cleverly) DataHoarderDB.

## Information is logged per character, and includes/will include:
* Continents, Zones, and Instances visited, and how many times, and how much (non-AFK) time spent in them
* Amount of XP gained (as a percentage of a level), divided into the respective zones in which it was acquired, also separated by Quest vs kill XP
* Amount of mobs killed, by type / unique name, with some filtering applied to avoid oddities in quests, such as vehicle mass-murder sections
* Amount of DPS done on average, throughout a zone. DPS is also tracked on a per-level basis (the average DPS you did per combat is saved as one atomic piece of information every time you levle up)
* Quests completed, and where
* _And much, much more_


## The goal

The purpose and ultimate goal of DataHoarderDB is to be able to provide enough information to another Addon, working title _"TellMyStory"_, to be able to calculate or otherwise extrapolate the overall progression of a character as you level, and present it in a nice and interesting graphical manner once your new character hits max level, or whenever you wish to view the "story".

Stats tracked will be added to DataHoarder as needed to fulfill this goal, however the information may well be useful for other addons. Currently DataHoarderDB is not necessarily created to be easily used for other purposes, but it is a SavedVariable, and is wholly contained within one database, so there's no reason the data couldn't be used by other addons.
