class Service
  extend Usable

  def self.call(*args, **kwargs, &block)
    new(*args, **kwargs).call(&block)
  end

  def call
    raise NotImplementedError, 'Implement service call method!'
  end

  private

  def log(msg)
    Rails.logger.info "[#{self.class.name}] #{msg}"
  end

  def info(msg)
    Rails.logger.info "[#{self.class.name}] #{msg}"
  end

  def error(msg)
    Rails.logger.error "[#{self.class.name}] #{msg}"
  end
end