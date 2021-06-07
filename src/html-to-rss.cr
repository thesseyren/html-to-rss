require "kemal"

require "./scraper-tree"

# TODO: Write documentation for `HtmlToRss`
module HtmlToRss
  VERSION = "0.1.0"

  macro render_template(filename)
    render "src/views/#{{{filename}}}.ecr", "src/views/base.ecr"
  end

  get "/" do |env|
    orgs = @@scraper_tree
    render_template "index"
  end

  get "/:org" do |env|
    org = @@scraper_tree.find {|i| i.path == env.params.url["org"]}

    if org.nil?
      render_404
    else
      full_host = "#{Kemal.config.scheme}://#{env.request.headers["Host"]}"
      render_template "organization"
    end
  end

  get "/rss/:org/:endpoint" do |env|
    org = @@scraper_tree.find {|i| i.path == env.params.url["org"]}

    if org.nil?
      render_404
    else
      scraper = org.scrapers.find {|i| i.path == env.params.url["endpoint"]}
      if scraper.nil?
        render_404
      else
        begin
          resp = scraper.run
        rescue ex
          render_500(env, ex, true)
        else
          env.response.content_type = "text/xml"
          resp
        end
      end
    end
  end

  after_all do |env|
    env.response.headers["Content-Type"] += "; charset=utf-8"
  end

  Kemal.run

end
