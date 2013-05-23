# Vendor.
cheerio = require 'cheerio'
_ = require 'underscore'
errTo = require 'errto'
moment = require 'moment'

# Libs.
myutil = require '../util'
Model = require('./model')()

class @Speech

  @parse: (speech, context, done) ->
    noErr = errTo.bind null, done

    ###
    Here is an example of the structure of a speech:

    Interjection and continue only provide metadata about members who make
    interjections. The actual text of the interjection and continuation can
    be found in `talk.text`.

        talk.start
          talker
        talk.text
        interjection
          talk.start
          talk.text
        continue
          talk.start
          talk.text
        interjection
        continue
    ###

    # Speaker.
    speaker = myutil.camelizeKeysExt speech['talk.start'].talker
    speaker.name = speaker.name._
    # Text.
    talkText = speech['talk.text'].body._

    # Extract stuff from speech.
    result = Speech.extractContent talkText

    # SpeakerId.
    await Model.Member.findByNameFromHansard(speaker.name)
    .done noErr defer dbSpeaker
    # WARNING: dbSpeaker can be `null`

    speakerId = if dbSpeaker? then dbSpeaker.id else null

    # Date time.
    date = moment context.session.date
    time = moment result.time, 'HH:mm'
    date.hour time.hour()
    date.minute time.minute()

    # Save.
    await Model.Speech.create
      date: date.toDate()
      content: result.html
      hasChairQuestion: result.hasChairQuestion
      # FK.
      speakerId: speakerId
      majorId: context.major?.id
      minorId: context.minor?.id
      stageId: context.stage?.id
      # Denorm.
      electorate: result.electorate
      ministerialTitles: result.ministerialTitles
      speakerName: speaker.name # We also have result.memberName
      party: speaker.party
      mpid: speaker.nameId
      # JSON.
      json: JSON.stringify
        chairQuestionResult: result.chairQuestionResult
    .done noErr defer speech

    done null, speech

  @extractContent: (talkText) ->
    $ = cheerio.load talkText

    result =
      electorate: $('span.HPS-Electorate').text()
      ministerialTitles: $('span.HPS-MinisterialTitles').text()
      time: $('span.HPS-Time').text()
      memberName: $('span.HPS-MemberSpeech').text() # e.g. Senate IAN MACDONALD
      hasChairQuestion: false
      chairQuestionResult: null

    $('span.HPS-Normal').each -> @replaceWith @html().trim()

    $('p').each ->
      @html @html().trim()
      @removeAttr 'class'
      @removeAttr 'style'

      # Apply nested style to top-level `p`
      liftStyle = (sel, clazz) =>
        if (el = @find(sel)).length
          @replaceWith "<p class='#{clazz}'>#{@html()}</p>"

      liftStyle 'span.HPS-OfficeInterjecting', 'interjecting office'
      liftStyle 'span.HPS-MemberIInterjecting', 'interjecting imember'
      liftStyle 'span.HPS-MemberInterjecting', 'interjecting member'
      liftStyle 'span.HPS-MemberContinuation', 'continuation'

    # Remove header.
    $('a[type=MemberSpeech]').remove()
    $('span.HPS-Electorate').remove()
    $('span.HPS-MinisterialTitles').remove()
    $('span.HPS-Time').remove()

    # Does this speech contain a question?
    # Relies upon liftStyle having run above.
    $('.interjecting.office').each ->
      matches = @text().match /The question is that(.*)./i
      if matches?
        result.hasChairQuestion = true
        result.chairQuestionResult = @next()?.text()
        #matches = @text().match /Question negatived/i
        #if matches?

    html = $.html()
    html = html.replace '() ():', ''
    html = html.replace '(—) ():', ''
    result.html = html
    result
