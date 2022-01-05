from icecap_framework import *

class Application(GenericElfComponent):

    def arg_json(self):
        return {
        }

class SerialServer(GenericElfComponent):

    def arg_json(self):
        return {
        }

class TimerServer(GenericElfComponent):

    def arg_json(self):
        return {
        }

class Composition(BaseComposition):

    def compose(self):
        self.component(Application, 'application')
        self.component(SerialServer, 'serial_server')
        self.component(TimerServer, 'timer_server')

Composition.from_env().run()
