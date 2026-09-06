extends Node

var _player: AudioStreamPlayer


func _ready() -> void:
    _player = AudioStreamPlayer.new()
    add_child(_player)


func play_victory(critical := false) -> void:
    var stream := _build_stream(critical)
    _player.stream = stream
    _player.play()


func _build_stream(critical: bool) -> AudioStreamWAV:
    var rate := 44100
    var duration := 1.15 if critical else 0.9
    var samples := int(rate * duration)
    var bytes := PackedByteArray()
    bytes.resize(samples * 2)

    var notes := [72, 76, 79, 84] if not critical else [67, 72, 76, 79, 84]
    var step := duration / float(notes.size())

    for i in range(samples):
        var t := float(i) / float(rate)
        var note_index := min(int(t / step), notes.size() - 1)
        var local_t := t - float(note_index) * step
        var hz := 440.0 * pow(2.0, (float(notes[note_index]) - 69.0) / 12.0)
        var env := min(1.0, local_t / 0.018) * max(0.0, 1.0 - local_t / step)
        var tone := sin(TAU * hz * t) * 0.72
        tone += sin(TAU * hz * 2.0 * t) * 0.16
        tone += sin(TAU * hz * 0.5 * t) * 0.08
        var value := int(clamp(tone * env, -1.0, 1.0) * 24000.0)
        var u := value & 0xffff
        bytes[i * 2] = u & 0xff
        bytes[i * 2 + 1] = (u >> 8) & 0xff

    var wav := AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate = rate
    wav.stereo = false
    wav.data = bytes
    return wav
