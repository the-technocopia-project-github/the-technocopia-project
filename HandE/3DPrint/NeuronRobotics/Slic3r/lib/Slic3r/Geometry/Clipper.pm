package Slic3r::Geometry::Clipper;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(safety_offset safety_offset_ex offset offset_ex collapse_ex
    diff_ex diff union_ex intersection_ex xor_ex PFT_EVENODD JT_MITER JT_ROUND
    JT_SQUARE is_counter_clockwise);

use Math::Clipper 1.17 qw(:cliptypes :polyfilltypes :jointypes is_counter_clockwise area);
use Slic3r::Geometry qw(scale);
our $clipper = Math::Clipper->new;

sub safety_offset {
    my ($polygons, $factor) = @_;
    return Math::Clipper::offset($polygons, $factor // (scale 1e-05), 100000, JT_MITER, 2);
}

sub safety_offset_ex {
    # offset polygons and then apply holes to the right contours
    return @{ union_ex([ safety_offset(@_) ]) };
}

sub offset {
    my ($polygons, $distance, $scale, $joinType, $miterLimit) = @_;
    $scale      ||= 100000;
    $joinType   //= JT_MITER;
    $miterLimit //= 3;
    
    my $offsets = Math::Clipper::offset($polygons, $distance, $scale, $joinType, $miterLimit);
    return @$offsets;
}

sub offset_ex {
    # offset polygons and then apply holes to the right contours
    return @{ union_ex([ offset(@_) ]) };
}

sub diff_ex {
    my ($subject, $clip, $safety_offset) = @_;
    
    $clipper->clear;
    $clipper->add_subject_polygons($subject);
    $clipper->add_clip_polygons($safety_offset ? safety_offset($clip) : $clip);
    return [
        map Slic3r::ExPolygon->new($_),
            @{ $clipper->ex_execute(CT_DIFFERENCE, PFT_NONZERO, PFT_NONZERO) },
    ];
}

sub diff {
    my ($subject, $clip, $safety_offset) = @_;
    
    $clipper->clear;
    $clipper->add_subject_polygons($subject);
    $clipper->add_clip_polygons($safety_offset ? safety_offset($clip) : $clip);
    return [
        map Slic3r::Polygon->new($_),
            @{ $clipper->execute(CT_DIFFERENCE, PFT_NONZERO, PFT_NONZERO) },
    ];
}

sub union_ex {
    my ($polygons, $jointype, $safety_offset) = @_;
    $jointype = PFT_NONZERO unless defined $jointype;
    $clipper->clear;
    $clipper->add_subject_polygons($safety_offset ? safety_offset($polygons) : $polygons);
    return [
        map Slic3r::ExPolygon->new($_),
            @{ $clipper->ex_execute(CT_UNION, $jointype, $jointype) },
    ];
}

sub intersection_ex {
    my ($subject, $clip, $jointype, $safety_offset) = @_;
    $jointype = PFT_NONZERO unless defined $jointype;
    $clipper->clear;
    $clipper->add_subject_polygons($subject);
    $clipper->add_clip_polygons($safety_offset ? safety_offset($clip) : $clip);
    return [
        map Slic3r::ExPolygon->new($_),
            @{ $clipper->ex_execute(CT_INTERSECTION, $jointype, $jointype) },
    ];
}

sub xor_ex {
    my ($subject, $clip, $jointype) = @_;
    $jointype = PFT_NONZERO unless defined $jointype;
    $clipper->clear;
    $clipper->add_subject_polygons($subject);
    $clipper->add_clip_polygons($clip);
    return [
        map Slic3r::ExPolygon->new($_),
            @{ $clipper->ex_execute(CT_XOR, $jointype, $jointype) },
    ];
}

sub collapse_ex {
    my ($polygons, $width) = @_;
    my @result = offset(
        [ offset($polygons, -$width/2,) ],
        +$width/2,
    );
    return union_ex([@result]);
}

sub simplify_polygon {
    my ($polygon, $pft) = @_;
    return @{ Math::Clipper::simplify_polygon($polygon, $pft // PFT_NONZERO) };
}

sub simplify_polygons {
    my ($polygons, $pft) = @_;
    return @{ Math::Clipper::simplify_polygons($polygons, $pft // PFT_NONZERO) };
}

1;
