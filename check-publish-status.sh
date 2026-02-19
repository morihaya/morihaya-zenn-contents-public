#!/bin/bash

# ちょいちょい忘れるPublished: trueの確認をするためのスクリプト
grep published articles/*.md | grep "published: f"
