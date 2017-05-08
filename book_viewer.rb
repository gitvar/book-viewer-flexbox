require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"

before do
  @title = "The Adventures of Sherlock Holmes"
  @author = "Sir Arthur Conan Doyle"
  @table_of_contents = File.readlines("data/toc.txt")
end

helpers do
  def insert_paragraphs(chapter, query = "")
    chapter.split("\n\n").each_with_index.map do |paragraph, index|
      paragraph = highlight(paragraph, query) unless query == ""
      "<p id=paragraph#{index}>#{paragraph}</p>"
    end.join
  end

  def highlight(text, query)
    text.gsub(query, %(<strong>#{query}</strong>))
  end
end

not_found do
  redirect "/"
end

get "/" do
  erb :home
end

get "/chapters/:number" do
  chapter_number = params[:number].to_i
  no_of_chapters = @table_of_contents.size
  redirect "/" unless (1..no_of_chapters).to_a.include?(chapter_number)

  @chapter_title = @table_of_contents[chapter_number - 1]
  @chapter = File.read("data/chp#{chapter_number}.txt")

  erb :chapter
end

# Calls the block for each chapter, passing that chapter's number, name, and
# the chapter contents.
def each_chapter
  @table_of_contents.each_with_index do |chapter_name, index|
    chapter_number = index + 1
    chapter_contents = File.read("data/chp#{chapter_number}.txt")
    yield chapter_number, chapter_name, chapter_contents
  end
end

# This method returns an Array of Hashes representing chapters that match the specified query. Each Hash contain values for its :chapter_name, :chapter_number and paragraph keys. The :paragraph key points to another hash; the matching_paragraphs hash.
def chapters_matching(query)
  results = []

  return results if query.nil? || query == ''

  each_chapter do |chapter_number, chapter_name, chapter_contents|
    matching_paragraphs = {}

    # The 'matching_paragraphs' hash contains all the paragraphs (from each
    # chapter) which contain the search query.
    chapter_contents.split("\n\n").each_with_index do |paragraph, index|
      matching_paragraphs[index] = paragraph if paragraph.include?(query)
    end

    # If there is at least one paragraph with text that match the search query,
    # save the chapter number, the chapter name and the HASH of all the
    # matching paragraphs to the results array.
    if matching_paragraphs.any?
      results << { number: chapter_number, name: chapter_name,
      paragraphs: matching_paragraphs, query: query }
    end
  end

  results
end

get "/search" do
  @results = chapters_matching(params[:query])

  erb :search
end
