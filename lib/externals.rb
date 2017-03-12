
module Externals # mix-in

  def env_var; @env_var ||= EnvVar.new; end

  def disk ; @disk  ||= external; end
  def log  ; @log   ||= external; end
  def shell; @shell ||= external; end

  def runner; @runner ||= external; end
  def storer; @storer ||= external; end
  def differ; @differ ||= external; end
  def ragger; @ragger ||= external; end
  def zipper; @zipper ||= external; end

  private

  def external
    key = name_of(caller)
    var = env_var.value(key + '_class')
    Object.const_get(var).new(self)
  end

  include NameOfCaller

end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# External root-dirs and class-names are set using environment variables.
# This gives tests a way to do Parameterize-From-Above in a way that can
# potentially tunnel through a *deep* stack. For example, I can set an
# environment variable and then run a controller test which issues
# GETs/POSTs, which work their way through the rails stack, eventually
# reaching app/models/dojo.rb (possibly in a different thread)
# where the specificied Double/Mock/Stub class or path takes effect.
#
# The external objects are held using
#    @name ||= ...
# I use ||= partly for optimization and partly for testing
# (where it is sometimes handy that it is the same object)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
