'use client';

import { useRestTimerContext } from '@/contexts/RestTimerContext';
import { Label } from '@/components/ui/label';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Switch } from '@/components/ui/switch';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { NotificationType } from '@/types/rest-timer';

export function RestTimerSettings() {
  const { settings, setSettings } = useRestTimerContext();

  return (
    <div className="space-y-6">
      <div className="space-y-3">
        <Label className="text-base">Notification Type</Label>
        <RadioGroup
          value={settings.notificationType}
          onValueChange={(value: NotificationType) =>
            setSettings({ notificationType: value })
          }
          className="grid grid-cols-2 gap-2"
        >
          <div className="flex items-center space-x-2">
            <RadioGroupItem value="sound" id="sound" />
            <Label htmlFor="sound" className="font-normal">
              Sound only
            </Label>
          </div>
          <div className="flex items-center space-x-2">
            <RadioGroupItem value="vibrate" id="vibrate" />
            <Label htmlFor="vibrate" className="font-normal">
              Vibration only
            </Label>
          </div>
          <div className="flex items-center space-x-2">
            <RadioGroupItem value="both" id="both" />
            <Label htmlFor="both" className="font-normal">
              Both
            </Label>
          </div>
          <div className="flex items-center space-x-2">
            <RadioGroupItem value="none" id="none" />
            <Label htmlFor="none" className="font-normal">
              None
            </Label>
          </div>
        </RadioGroup>
      </div>

      <div className="space-y-3">
        <Label className="text-base">Default Rest Time</Label>
        <Select
          value={String(settings.defaultRestSeconds)}
          onValueChange={value =>
            setSettings({ defaultRestSeconds: parseInt(value, 10) })
          }
        >
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="60">1 minute</SelectItem>
            <SelectItem value="90">1.5 minutes</SelectItem>
            <SelectItem value="120">2 minutes</SelectItem>
            <SelectItem value="180">3 minutes</SelectItem>
            <SelectItem value="240">4 minutes</SelectItem>
            <SelectItem value="300">5 minutes</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <div className="flex items-center justify-between">
        <div className="space-y-0.5">
          <Label className="text-base">Auto-start after set</Label>
          <p className="text-sm text-muted-foreground">
            Automatically start timer when you log a set
          </p>
        </div>
        <Switch
          checked={settings.autoStartEnabled}
          onCheckedChange={checked =>
            setSettings({ autoStartEnabled: checked })
          }
        />
      </div>
    </div>
  );
}
