require_relative 'ut/adapters/rally'

module Ut

  class Ut

    @@adapter_classes = [
      ::Ut::Adapters::Rally
    ]

    def initialize
    end

    # Command
    def list(iteration_name)
      iteration = adapter.iteration iteration_name
      stories   = adapter.stories iteration

      stories.each do |story|
        populate_story story
      end
    end

    def populate_story(story)
      id    = story.formatted_i_d
      name  = story.name
      state = \
        story.schedule_state == 'In-Progress' ?
          'P' :
          story.schedule_state.split('')[0]

      puts "[#{state}] #{id} - #{name}"
      print "\n"

      story.tasks.each do |task|
        puts "  * #{task}"
      end

      print "\n"

      loop do
        puts "Would you like to:"
        puts "  (1) add tasks based on requirements"
        puts "  (2) add bug tasks"
        puts "  (3) add boilerplate"
        puts "  (4) add a new task"
        puts "  (5) delete a task"
        puts "  (6) delete all tasks"
        puts "  (7) skip"
        puts "  (8) exit"

        input = ask

        begin
          if input == ?1 # add tasks based on requirements
            adapter.add_tasks_from_requirements story

          elsif input == ?2 # add bug tasks
            adapter.add_tasks story, ['Triage', 1.0] + boilerplate_tasks

          elsif input == ?3 # add boilerplate
            adapter.add_tasks story, boilerplate_tasks

          elsif input == ?4 # add a new task
            puts 'Name a task and hit enter:'
            name = ask
            adapter.add_task story, name, 1.0

          elsif input == ?5 # delete a task
            puts 'Name a task and hit enter:'
            name = ask
            adapter.delete_task story, name

          elsif input == ?6 # delete all tasks
            adapter.delete_tasks story

          elsif input == ?7 # skip
            return

          elsif input == ?8 # exit
            puts 'Exiting...'
            exit

          end

        rescue NoMethodError => e
          puts 'Could not populate story. Try again.'

          populate_story story
        end
      end
    end

    def boilerplate_tasks
      tasks = [
        ['Dev QA',      1.0],
        ['Code Review', 1.0]
      ]

      unless ENV['IS_PROD']
        tasks << ['Deploy to am-test',  1.0]
        tasks << ['Confirm on am-test', 1.0]
        tasks << ['QA Test',            1.0]
      end

      tasks
    end

    def ask(*args)
      STDIN.gets.strip
    end

    def adapter_name
      adapter_name = ENV['TALLY_ADAPTER'] || 'rally'
    end

    def adapter
      @adapter ||= eval("::Ut::Adapters::#{adapter_name.capitalize}").new
    end

  end

end

