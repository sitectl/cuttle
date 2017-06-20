# This file is part of Ansible
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

import time
from ansible.plugins.callback import CallbackBase


def secs_to_str(seconds):
    # http://bytes.com/topic/python/answers/635958-handy-short-cut-formatting-elapsed-time-floating-point-seconds
    def rediv(ll, b):
        return list(divmod(ll[0], b)) + ll[1:]

    numbers = tuple(reduce(rediv, [[seconds * 1000, ], 1000, 60, 60]))
    return "%d:%02d:%02d.%03d" % numbers


def fill_str(string, fchar="*"):
    if len(string) == 0:
        width = 79
    else:
        string = "%s " % string
        width = 79 - len(string)

    if width < 3:
        width = 3
    filler = fchar * width

    return "%s%s " % (string, filler)


class CallbackModule(CallbackBase):
    def __init__(self, *args, **kwargs):
        self.count = 0
        self.stats = {}
        self.current = None
        self.tn = self.t0 = time.time()
        super(CallbackModule, self).__init__(*args, **kwargs)

    def v2_playbook_on_task_start(self, task, is_conditional):
        self.timestamp()

        if self.current is not None:
            # Record the running time of the last executed task
            self.stats[self.current] = time.time() - self.stats[self.current]

        # Record the start time of the current task
        self.current = task.get_name()
        self.stats[self.current] = time.time()
        self.count += 1

    def v2_playbook_on_setup(self):
        self.timestamp()

    def v2_playbook_on_play_start(self, play):
        self.timestamp()
        self._display.display(fill_str("", fchar="="))

    def v2_playbook_on_stats(self, play):
        self.timestamp()
        self._display.display(fill_str("", fchar="="))
        self._display.display("Total tasks: %d" % self.count)
        self._display.display(fill_str("", fchar="="))
        self._display.display("Slowest 25 Tasks")
        self._display.display(fill_str("", fchar="="))
        # Record the timing of the very last task
        if self.current is not None:
            self.stats[self.current] = time.time() - self.stats[self.current]

        # Sort the tasks by their running time
        results = sorted(
            self.stats.items(),
            key=lambda value: value[1],
            reverse=True,
        )

        # Print the timings
        for name, elapsed in results[:25]:
            name = '{0} '.format(name)
            elapsed = ' {0:.02f}s'.format(elapsed)
            self._display.display("{0:-<70}{1:->9}".format(name, elapsed))

    def timestamp(self):
        time_current = time.strftime('%A %d %B %Y  %H:%M:%S %z')
        time_elapsed = secs_to_str(time.time() - self.tn)
        time_total_elapsed = secs_to_str(time.time() - self.t0)
        self._display.display(
            fill_str(
                '%s (%s)       %s' % (time_current,
                                      time_elapsed,
                                      time_total_elapsed)
            )
        )
        self.tn = time.time()
