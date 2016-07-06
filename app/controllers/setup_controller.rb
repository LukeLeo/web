
class SetupController < ApplicationController

  # Regular two step setup
  # step 1. languages(+test in column 2)  (eg Java+JUnit)
  # step 2. instructions                  (eg Fizz_Buzz)
  def show_languages
    @id = id
    @title = 'create'
    languages_names = read(languages)
    index = choose_language(languages_names, id, dojo.katas)
    @languages = ::DisplayNamesSplitter.new(languages_names, index)
    @initial_language_index = @languages.selected_index
  end

  def language_pull_needed
    language_name = params['language']
        test_name = params['test'    ]
    language = languages[language_name + '-' + test_name]
    image_name = language.image_name
    answer = !dojo.runner.pulled?(image_name)
    render json: { pull_needed: answer }
  end

  def language_pull
    language_name = params['language']
        test_name = params['test'    ]
    language = languages[language_name + '-' + test_name]
    image_name = language.image_name
    dojo.runner.pull(image_name)
    render json: { }
  end

  def show_instructions
    @id = id
    @title = 'create'
    @language = params[:language]
    @test = params[:test]
    @exercises_names,@instructions = read_instructions
    @initial_exercise_index = choose_instructions(@exercises_names, id, dojo.katas)
  end

  def language_save
    language_name = params['language']
        test_name = params['test'    ]
    language = languages[language_name + '-' + test_name]
    instruction_name = params['exercise']
    instruction = instructions[instruction_name]
    manifest = katas.create_kata_manifest(language)
    manifest[:exercise] = instruction.name
    manifest[:visible_files]['instructions'] = instruction.text
    kata = katas.create_kata_from_kata_manifest(manifest)
    render json: { id: kata.id }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -
  # Custom exercise one-step setup

  def show_exercises
    @id = id
    @title = 'create'
    exercises_names = read(exercises)
    index = choose_language(exercises_names, id, dojo.katas)
    @languages = ::DisplayNamesSplitter.new(exercises_names, index)
    @initial_language_index = @languages.selected_index
  end

  def exercise_pull_needed
    language_name = params['language']
        test_name = params['test'    ]
    exercise = exercises[language_name + '-' + test_name]
    image_name = exercise.image_name
    answer = !dojo.runner.pulled?(image_name)
    render json: { pull_needed: answer }
  end

  def exercise_pull
    language_name = params['language']
        test_name = params['test'    ]
    exercise = exercises[language_name + '-' + test_name]
    image_name = exercise.image_name
    dojo.runner.pull(image_name)
    render json: { }
  end

  def exercise_save
    language_name = params['language']
        test_name = params['test']
    exercise = exercises[language_name + '-' + test_name]
    manifest = katas.create_kata_manifest(exercise)
    kata = katas.create_kata_from_kata_manifest(manifest)
    render json: { id: kata.id }
  end

  private

  include SetupChooser

  def read(manifests)
    manifests.map(&:display_name).sort
  end

  def read_instructions
    names = []
    instructions_hash =  {}
    instructions.each do |instruction|
      names << instruction.name
      instructions_hash[instruction.name] = instruction.text
    end
    [names.sort, instructions_hash]
  end

end
