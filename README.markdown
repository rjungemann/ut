# Ultimate Tally (ut)

Created by thefifthcircuit

## Is this project competing with...?

Ultimate Tally is a successor to tally (by obskein) and tally-ac by me.

It is not a competitor with Rallycat or the Chrome extension created by Chase.
In fact it works well in concert either of the above!

## Installation

    git clone https://github.com/thefifthcircuit/ut.git
    cd ut
    rake install

Be sure to set the `RALLY_USERNAME`, `RALLY_PASSWORD`, and `RALLY_PROJECT`
environment variables.

## Usage

    ut help
    ut list '<iteration_name>'
    ut update '<story_number>'
    RALLY_PROJECT='ACME' ut list '<iteration_name>'
    ut add requirements US1234
    ut add all US1234
    ut add bug_tasks US1234
    ut add boilerplate US1234
    ut delete US1234 '<task_name>'
    ut delete_all '<task_name>'

    # Bonus method
    ut generate_rallycatrc # generate a ~/.rallycatrc from ut settings! 

## Available Options

  * `RALLY_USERNAME='...' # required`
  * `RALLY_PASSWORD='...' # required`
  * `RALLY_PROJECT='...' # required`
  * `RALLY_URL='...' # defaults to "https://rally1.rallydev.com/slm"`
  * `TALLY_ADAPTER='...' # defaults to "rally"`
  * `IS_PROD='...' # defaults to false`

## Creating Your Own Adapter

Adapters respond to:

  * `iteration(iteration_name) #=> iteration_object`
  * `stories(iteration) #=> [story_object]`
  * `story_by_number(story_name) #=> [story_object]`
  * `add_tasks(story_object, pairs) #=> nil`
  * `add_task(story_object, name, estimate) #=> nil`
  * `delete_tasks(story_object) #=> nil`
  * `delete_task(story_object, name) #=> nil`

