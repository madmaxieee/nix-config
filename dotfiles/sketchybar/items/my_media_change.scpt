#!/usr/bin/osascript

-- This script runs an infinite loop that retrieves the "Now Playing"
-- media information and prints it to standard output as a JSON object every 2 seconds.
-- It only logs the output if it's different than the last output.

-- Required for using Objective-C frameworks like MediaRemote.
use framework "AppKit"

-- Global variable to store the last output.
global lastOutput

-- Initialize lastOutput to an empty string.
set lastOutput to ""

-- Handler to escape double quotes in a string for JSON compatibility.
on escape_for_json(the_text)
  set AppleScript's text item delimiters to "\""
  set the text_items to every text item of the_text
  set AppleScript's text item delimiters to "\\\""
  set the escaped_text to the text_items as string
  set AppleScript's text item delimiters to ""
  return escaped_text
end escape_for_json

on dumpInfoDict(theDict)
  set outputString to ""  -- Start with an empty string

  repeat with theKey in the keys of theDict
    set theValue to item theKey of theDict  -- Access value by key

    -- Construct the string to display for each key-value pair
    -- Using quoted form of to handle special characters in strings
    set outputString to outputString & theKey & " : " & theValue & linefeed
  end repeat

  return outputString -- Returns the entire string at the end to display in Result pane
end dumpInfoDict

repeat
  -- Block of code to be executed repeatedly.
  try
    -- Load the MediaRemote framework to access media information.
    set MediaRemote to current application's NSBundle's bundleWithPath:"/System/Library/PrivateFrameworks/MediaRemote.framework/"
    MediaRemote's load()

    -- Get the class for making "Now Playing" requests.
    set MRNowPlayingRequest to current application's NSClassFromString("MRNowPlayingRequest")

    -- Get the dictionary containing the track's metadata.
    set infoDict to MRNowPlayingRequest's localNowPlayingItem()'s nowPlayingInfo()

    -- Extract raw values from the metadata.
    set rawAppName to MRNowPlayingRequest's localNowPlayingPlayerPath()'s client()'s displayName()
    set rawTitle to (infoDict's valueForKey:"kMRMediaRemoteNowPlayingInfoTitle")
    set rawAlbum to (infoDict's valueForKey:"kMRMediaRemoteNowPlayingInfoAlbum")
    set rawArtist to (infoDict's valueForKey:"kMRMediaRemoteNowPlayingInfoArtist")

    -- Coerce to text, providing empty strings for missing values.
    if rawAppName is not missing value then
      set appName to rawAppName as text
    else
      set appName to ""
    end if
    if rawTitle is not missing value then
      set title to rawTitle as text
    else
      set title to ""
    end if
    if rawAlbum is not missing value then
      set album to rawAlbum as text
    else
      set album to ""
    end if
    if rawArtist is not missing value then
      set artist to rawArtist as text
    else
      set artist to ""
    end if

    -- Escape any double quotes within the text fields to ensure valid JSON.
    set escapedAppName to my escape_for_json(appName)
    set escapedTitle to my escape_for_json(title)
    set escapedAlbum to my escape_for_json(album)
    set escapedArtist to my escape_for_json(artist)

    -- Construct the JSON output string.
    set jsonOutput to "{\"app\":\"" & escapedAppName & "\",\"title\":\"" & escapedTitle & "\",\"album\":\"" & escapedAlbum & "\",\"artist\":\"" & escapedArtist & "\"}"

    -- only output if the output is different from the last one
    if jsonOutput is not equal to lastOutput then
      log jsonOutput
      set lastOutput to jsonOutput
    end if

    delay 2

  on error errorMessage
    -- If an error occurs (e.g., no music is playing), log an empty JSON object
    -- to ensure the output stream remains valid JSON, but only if different
    set jsonOutput to "{}"

    if jsonOutput is not equal to lastOutput then
      log "{}"
      set lastOutput to "{}"
    end if

    delay 2
  end try

end repeat
