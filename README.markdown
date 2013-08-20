# Ultimate Tally (ut)

Created by thefifthcircuit

## Is this project competing with...?

Ultimate Tally is a successor to tally (by obskein) and tally-ac by me.

It is not a competitor with Rallycat or similar tools. In fact it works well in
concert with Rallycat!

## Installation

    git clone https://github.com/thefifthcircuit/ut.git
    cd ut
    gem build ut.gemspec

Be sure to set the `RALLY_USERNAME`, `RALLY_PASSWORD`, and `RALLY_PROJECT`
environment variables.

## Usage

    ut list '<iteration_name>'
    ut add requirements US1234
    ut add all US1234
    ut add bug_tasks US1234
    ut add boilerplate US1234
    ut delete US1234 '<task_name>'
    ut delete_all '<task_name>'

## Available Options

  * `RALLY_USERNAME='...'`
  * `RALLY_PASSWORD='...'`
  * `RALLY_PROJECT='...'`
  * `RALLY_URL='...'`
  * `TALLY_ADAPTER='...'`
  * `IS_PROD='...' # true or false`

## Creating Your Own Adapter

Adapters respond to:

  * `iteration(iteration_name) #=> iteration_object`
  * `stories(iteration) #=> [story_object]`
  * `story_by_number(story_name) #=> [story_object]`
  * `add_tasks(story, pairs) #=> nil`
  * `add_task(story, name, estimate) #=> nil`
  * `delete_tasks(story) #=> nil`
  * `delete_task(story, name) #=> nil`

